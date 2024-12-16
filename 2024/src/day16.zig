const std = @import("std");
const print = std.debug.print;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const AutoHashMap = std.AutoHashMap;
const PriorityQueue = std.PriorityQueue;

const Direction = enum(usize) {
    UP = 0,
    RIGHT,
    DOWN,
    LEFT
};

const dr = [_]i32{ -1, 0, 1,  0 };
const dc = [_]i32{  0, 1, 0, -1 };

const LocationDist = struct {
    r: usize,
    c: usize,
    direction: Direction,
    dist: u32,
};

const Location = struct {
    r: usize,
    c: usize,
};

const Input = struct {
    map: ArrayList(ArrayList(u8)),
    start_r: usize,
    start_c: usize,
    end_r: usize,
    end_c: usize,

    const Self = @This();

    pub fn init(allocator: Allocator, file_name: []const u8) !Self {
        const file = try std.fs.cwd().openFile(file_name, .{});
        defer file.close();

        var buf_reader = std.io.bufferedReader(file.reader());
        var in_stream = buf_reader.reader();
        var buf: [1024]u8 = undefined;

        var map = ArrayList(ArrayList(u8)).init(allocator);
        var start_r: usize = 0;
        var start_c: usize = 0;
        var end_r: usize = 0;
        var end_c: usize = 0;

        while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line_buf| {
            var row = ArrayList(u8).init(allocator);

            for (0.., line_buf) |c, char| {
                if (char == '.' or char == '#') {
                    try row.append(char);
                } else if (char == 'S') {
                    start_r = map.items.len;
                    start_c = c;
                    try row.append('.');
                } else if (char == 'E') {
                    end_r = map.items.len;
                    end_c = c;
                    try row.append('.');
                }
            }

            try map.append(row);
        }

        return .{
            .map = map,
            .start_r = start_r,
            .start_c = start_c,
            .end_r = end_r,
            .end_c = end_c,
        };
    }

    pub fn deinit(self: *Self) void {
        for (self.*.map.items) |row| {
            row.deinit();
        }
        self.*.map.deinit();
    }
};

fn inBounds(r: i32, c: i32, rows: usize, cols: usize) bool {
    const rows_i32 = @as(i32, @intCast(rows));
    const cols_i32 = @as(i32, @intCast(cols));

    return (r >= 0 and r < rows_i32 and c >= 0 and c < cols_i32);
}

fn compareFn(_: void, l1: LocationDist, l2: LocationDist) std.math.Order {
    if (l1.dist < l2.dist) {
        return std.math.Order.lt;
    } else if (l1.dist == l2.dist) {
        return std.math.Order.eq;
    }

    return std.math.Order.gt;
}

fn clockwise(direction: Direction) Direction {
    const dir = @intFromEnum(direction);
    return @enumFromInt((dir + 1) % 4);
}

fn counterClockwise(direction: Direction) Direction {
    const dir = @intFromEnum(direction);
    if (dir == 0) {
        return @enumFromInt(3);
    }
    return @enumFromInt(dir - 1);
}

fn invert(direction: Direction) Direction {
    const dir = @intFromEnum(direction);
    return @enumFromInt((dir + 2) % 4);
}

pub fn solvePartOne() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var input = try Input.init(allocator, "examples/day16.txt");
    defer input.deinit();

    const rows = input.map.items.len;
    const cols = input.map.items[0].items.len;

    // r, c, direction
    var dist = ArrayList(ArrayList([4]u32)).init(allocator);

    for (0..rows) |_| {
        var row = ArrayList([4]u32).init(allocator);
        for (0..cols) |_| {
            var cell_dir: [4]u32 = undefined;
            for (0..4) |dir| {
                cell_dir[dir] = std.math.maxInt(u32);
            }
            try row.append(cell_dir);
        }
        try dist.append(row);
    }

    const start_direction = Direction.RIGHT;

    dist.items[input.start_r].items[input.start_c][@intFromEnum(start_direction)] = 0;

    var pq = PriorityQueue(LocationDist, void, compareFn).init(allocator, {});
    defer pq.deinit();

    try pq.add(.{
        .r = input.start_r,
        .c = input.start_c,
        .direction = start_direction,
        .dist = 0
    });

    while (pq.items.len != 0) {
        const curr = pq.remove();

        // we can move forward
        try moveForward(curr, input.map, &pq, &dist);

        // or rotate 90 degrees clockwise
        try rotate(curr, true, &pq, &dist);

        // or rotate 90 degrees counterclockwise
        try rotate(curr, false, &pq, &dist);
    }

    var res: u32 = std.math.maxInt(u32);
    for (0..4) |dir| {
        res = @min(dist.items[input.end_r].items[input.end_c][dir], res);
    }

    for (dist.items) |row| {
        row.deinit();
    }
    dist.deinit();

    print("{d}\n", .{res});
}

pub fn solvePartTwo() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var input = try Input.init(allocator, "examples/day16.txt");
    defer input.deinit();

    const dist_from_start = try dijkstra(
        allocator, 
        input.start_r,
        input.start_c,
        Direction.RIGHT,
        input.map
    );

    // dist_from_end[end_dir][r][c][dir]
    // minimum distance from end to (r, c) so that
    // starting direction is end_dir
    // and direction at (r, c) is dir
    var dist_from_end: [4]ArrayList(ArrayList([4]u32)) = undefined;
    for (0..4) |end_dir| {
        const dist = try dijkstra(
            allocator,
            input.end_r,
            input.end_c,
            invert(@enumFromInt(end_dir)),
            input.map,
        );
        dist_from_end[end_dir] = dist;
    }

    var min_dist_start_end: u32 = std.math.maxInt(u32);
    for (0..4) |dir| {
        min_dist_start_end = @min(
            dist_from_start.items[input.end_r].items[input.end_c][dir],
            min_dist_start_end
        );
    }

    var on_optimal_path = AutoHashMap(Location, void).init(allocator);
    defer on_optimal_path.deinit();

    for (0.., input.map.items) |r, row| {
        for (0.., row.items) |c, _| {
            // don't count walls
            if (input.map.items[r].items[c] == '#') {
                continue;
            }

            // if already at optimal path skip it
            if (on_optimal_path.contains(.{.r = r, .c = c})) {
                continue;
            }

            // for every direction we can end up at (r, c)
            for (0..4) |dir| {
                const from_start = dist_from_start.items[r].items[c][dir];

                const invert_direction = invert(@enumFromInt(dir));
                const invert_dir = @intFromEnum(invert_direction);
                var from_end: u32 = std.math.maxInt(u32);
                // for every direction we might end up at end.
                for (0..4) |end_dir| {
                    from_end = @min(
                        from_end,
                        dist_from_end[end_dir].items[r].items[c][invert_dir]
                    );
                }

                if (from_start + from_end == min_dist_start_end) {
                    try on_optimal_path.put(.{.r = r, .c = c}, {});
                }
            }
        }
    }

    for (dist_from_start.items) |row| {
        row.deinit();
    }
    dist_from_start.deinit();

    for (0..4) |dir| {
        for (dist_from_end[dir].items) |row| {
            row.deinit();
        }
        dist_from_end[dir].deinit();
    }

    print("{d}\n", .{on_optimal_path.count()});
}

fn dijkstra(
    allocator: Allocator,
    start_r: usize,
    start_c: usize,
    start_direction: Direction,
    map: ArrayList(ArrayList(u8))) !ArrayList(ArrayList([4]u32)) {

    const rows = map.items.len;
    const cols = map.items[0].items.len;

    var dist = ArrayList(ArrayList([4]u32)).init(allocator);

    for (0..rows) |_| {
        var row = ArrayList([4]u32).init(allocator);
        for (0..cols) |_| {
            var cell_dir: [4]u32 = undefined;
            for (0..4) |dir| {
                cell_dir[dir] = std.math.maxInt(u32);
            }
            try row.append(cell_dir);
        }
        try dist.append(row);
    }

    dist.items[start_r].items[start_c][@intFromEnum(start_direction)] = 0;

    var pq = PriorityQueue(LocationDist, void, compareFn).init(allocator, {});
    defer pq.deinit();

    try pq.add(.{
        .r = start_r,
        .c = start_c,
        .direction = start_direction,
        .dist = 0
    });

    while (pq.items.len != 0) {
        const curr = pq.remove();

        // we can move forward
        try moveForward(curr, map, &pq, &dist);

        // or rotate 90 degrees clockwise
        try rotate(curr, true, &pq, &dist);

        // or rotate 90 degrees counterclockwise
        try rotate(curr, false, &pq, &dist);
    }

    return dist;
}

fn moveForward(
    curr: LocationDist,
    map: ArrayList(ArrayList(u8)),
    pq: *PriorityQueue(LocationDist, void, compareFn),
    dist: *ArrayList(ArrayList([4]u32))) !void {

    const rows = map.items.len;
    const cols = map.items[0].items.len;

    const dir: usize = @intFromEnum(curr.direction);

    const next_r_i32 = @as(i32, @intCast(curr.r)) + dr[dir];
    const next_c_i32 = @as(i32, @intCast(curr.c)) + dc[dir];

    if (!inBounds(next_r_i32, next_c_i32, rows, cols)) {
        return;
    }

    const next_r: usize = @intCast(next_r_i32);
    const next_c: usize = @intCast(next_c_i32);

    if (map.items[next_r].items[next_c] == '#') {
        return;
    }

    var next_dist = dist.items[next_r].items[next_c][dir];
    const curr_dist = dist.items[curr.r].items[curr.c][dir];

    if (next_dist > curr_dist + 1) {
        next_dist = curr_dist + 1;
        dist.items[next_r].items[next_c][dir] = next_dist;
        try pq.add(.{
            .r = next_r,
            .c = next_c,
            .dist = next_dist,
            .direction = curr.direction,
        });
    }
}

fn rotate(
    curr: LocationDist,
    rotate_clockwise: bool,
    pq: *PriorityQueue(LocationDist, void, compareFn),
    dist: *ArrayList(ArrayList([4]u32))) !void {

    const dir: usize = @intFromEnum(curr.direction);

    var next_direction: Direction = undefined;
    if (rotate_clockwise) {
        next_direction = clockwise(curr.direction);
    } else {
        next_direction = counterClockwise(curr.direction);
    }
    const next_dir = @intFromEnum(next_direction);

    var next_dist = dist.items[curr.r].items[curr.c][next_dir];
    const curr_dist = dist.items[curr.r].items[curr.c][dir];

    if (next_dist > curr_dist + 1000) {
        next_dist = curr_dist + 1000;
        dist.items[curr.r].items[curr.c][next_dir] = next_dist;
        try pq.add(.{
            .r = curr.r,
            .c = curr.c,
            .dist = next_dist,
            .direction = next_direction,
        });
    }
}
