const std = @import("std");
const print = std.debug.print;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const AutoHashMap = std.AutoHashMap;

const Direction = enum(usize) {
    UP = 0,
    RIGHT,
    DOWN,
    LEFT
};

const dr = [_]i32{ -1, 0, 1,  0 };
const dc = [_]i32{  0, 1, 0, -1 };

const Location = struct {
    r: usize,
    c: usize,
};

const Input = struct {
    map: ArrayList(ArrayList(u8)),
    robot_r: usize,
    robot_c: usize,
    movements: ArrayList(Direction),

    const Self = @This();

    pub fn init(allocator: Allocator, file_name: []const u8) !Self {
        const file = try std.fs.cwd().openFile(file_name, .{});
        defer file.close();

        var buf_reader = std.io.bufferedReader(file.reader());
        var in_stream = buf_reader.reader();
        var buf: [1024]u8 = undefined;

        var map = ArrayList(ArrayList(u8)).init(allocator);
        var movements = ArrayList(Direction).init(allocator);
        var parse_map = true;
        var robot_r: usize = 0;
        var robot_c: usize = 0;

        while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line_buf| {
            if (std.mem.eql(u8, line_buf, "")) {
                parse_map = false;
                continue;
            }

            if (parse_map) {
                var row = ArrayList(u8).init(allocator);

                for (0.., line_buf) |c, char| {
                    if (char == '.' or char == '#' or char == 'O') {
                        try row.append(char);
                    } else if (char == '@') {
                        robot_r = map.items.len;
                        robot_c = c;
                        try row.append('.');
                    }
                }

                try map.append(row);
            } else {
                for (line_buf) |char| {
                    var direction: Direction = undefined;

                    if (char == '^') {
                        direction = Direction.UP;
                    } else if (char == '>') {
                        direction = Direction.RIGHT;
                    } else if (char == 'v') {
                        direction = Direction.DOWN;
                    } else if (char == '<') {
                        direction = Direction.LEFT;
                    }

                    try movements.append(direction);
                }
            }
        }

        return .{
            .map = map,
            .movements = movements,
            .robot_r = robot_r,
            .robot_c = robot_c,
        };
    }

    pub fn deinit(self: *Self) void {
        self.*.movements.deinit();

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

pub fn solvePartOne() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var input = try Input.init(allocator, "examples/day15.txt");
    defer input.deinit();

    const rows = input.map.items.len;
    const cols = input.map.items[0].items.len;

    var robot_r = input.robot_r;
    var robot_c = input.robot_c;

    for (input.movements.items) |direction| {
        const dir: usize = @intFromEnum(direction);

        const next_robot_r_i32 = @as(i32, @intCast(robot_r)) + dr[dir];
        const next_robot_c_i32 = @as(i32, @intCast(robot_c)) + dc[dir];

        if (!inBounds(next_robot_r_i32, next_robot_c_i32, rows, cols)) {
            continue;
        }

        const next_robot_r: usize = @intCast(next_robot_r_i32);
        const next_robot_c: usize = @intCast(next_robot_c_i32);

        if (input.map.items[next_robot_r].items[next_robot_c] == '#') {
            continue;
        }

        if (input.map.items[next_robot_r].items[next_robot_c] == '.') {
            robot_r = next_robot_r;
            robot_c = next_robot_c;
            continue;
        }

        if (findFirstEmpty(next_robot_r, next_robot_c, input.map, direction)) |l| {
            const r = l.r;
            const c = l.c;

            input.map.items[r].items[c] = 'O';
            input.map.items[next_robot_r].items[next_robot_c] = '.';

            robot_r = next_robot_r;
            robot_c = next_robot_c;
        }
    }


    var res: u32 = 0;
    for (0.., input.map.items) |r, row| {
        for (0.., row.items) |c, char| {
            if (char == 'O') {
                res += @as(u32, @intCast((r * 100 + c)));
            }
        }
    }
    print("{d}\n", .{res});
}

fn findFirstEmpty(
    start_r: usize,
    start_c: usize,
    map: ArrayList(ArrayList(u8)),
    direction: Direction) ?Location {

    var r = start_r;
    var c = start_c;
    const dir: usize = @intFromEnum(direction);

    const rows = map.items.len;
    const cols = map.items[0].items.len;

    while (true) {
        const next_r_i32 = @as(i32, @intCast(r)) + dr[dir];
        const next_c_i32 = @as(i32, @intCast(c)) + dc[dir];

        if (!inBounds(next_r_i32, next_c_i32, rows, cols)) {
            return null;
        }

        const next_r: usize = @intCast(next_r_i32);
        const next_c: usize = @intCast(next_c_i32);

        if (map.items[next_r].items[next_c] == '#') {
            return null;
        }

        if (map.items[next_r].items[next_c] == '.') {
            return .{.r = next_r, .c = next_c};
        }

        r = next_r;
        c = next_c;
    }
}

pub fn solvePartTwo() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var input = try Input.init(allocator, "examples/day15.txt");
    defer input.deinit();

    var map = ArrayList(ArrayList(u8)).init(allocator);

    var robot_r = input.robot_r;
    var robot_c = input.robot_c;

    for (input.map.items) |row| {
        var new_row = ArrayList(u8).init(allocator);
        for (row.items) |char| {
            if (char == 'O') {
                try new_row.append('[');
                try new_row.append(']');
            } else {
                try new_row.append(char);
                try new_row.append(char);
            }
        }
        try map.append(new_row);
    }

    robot_c = 2*robot_c;

    for (input.map.items) |row| {
        row.deinit();
    }
    input.map.deinit();
    input.map = map;

    const rows = input.map.items.len;
    const cols = input.map.items[0].items.len;

    for (input.movements.items) |direction| {
        const dir: usize = @intFromEnum(direction);

        const next_robot_r_i32 = @as(i32, @intCast(robot_r)) + dr[dir];
        const next_robot_c_i32 = @as(i32, @intCast(robot_c)) + dc[dir];

        if (!inBounds(next_robot_r_i32, next_robot_c_i32, rows, cols)) {
            continue;
        }

        const next_robot_r: usize = @intCast(next_robot_r_i32);
        const next_robot_c: usize = @intCast(next_robot_c_i32);

        if (input.map.items[next_robot_r].items[next_robot_c] == '#') {
            continue;
        }

        if (input.map.items[next_robot_r].items[next_robot_c] == '.') {
            robot_r = next_robot_r;
            robot_c = next_robot_c;
            continue;
        }

        if (direction == Direction.LEFT or direction == Direction.RIGHT) {
            if (findFirstEmpty(next_robot_r, next_robot_c, input.map, direction)) |l| {
                var r = l.r;
                var c = l.c;

                var back_direction: Direction = undefined;
                if (direction == Direction.LEFT) {
                    back_direction = Direction.RIGHT;
                } else {
                    back_direction = Direction.LEFT;
                }
                const back_dir: usize = @intFromEnum(back_direction);

                while (r != next_robot_r or c != next_robot_c) {
                    const back_r: usize = @intCast(@as(i32, @intCast(r)) + dr[back_dir]);
                    const back_c: usize = @intCast(@as(i32, @intCast(c)) + dc[back_dir]);

                    input.map.items[r].items[c] = input.map.items[back_r].items[back_c];
                    r = back_r;
                    c = back_c;
                }

                input.map.items[next_robot_r].items[next_robot_c] = '.';

                robot_r = next_robot_r;
                robot_c = next_robot_c;
            }
        } else {
            const start_r = next_robot_r;
            var start_c = next_robot_c;

            if (input.map.items[start_r].items[start_c] == ']') {
                start_c -= 1;
            }

            const moving_boxes_opt = try findAllMoving(allocator, start_r, start_c, input.map, direction);
            if (moving_boxes_opt) |moving_boxes| {
                for (moving_boxes.items) |l| {
                    const next_r: usize = @intCast(@as(i32, @intCast(l.r)) + dr[dir]);
                    const next_c: usize = @intCast(@as(i32, @intCast(l.c)) + dc[dir]);

                    input.map.items[next_r].items[next_c] = '[';
                    input.map.items[next_r].items[next_c + 1] = ']';

                    input.map.items[l.r].items[l.c] = '.';
                    input.map.items[l.r].items[l.c + 1] = '.';
                }

                robot_r = next_robot_r;
                robot_c = next_robot_c;

                moving_boxes.deinit();
            }
        }
    }

    var res: u32 = 0;
    for (0.., input.map.items) |r, row| {
        for (0.., row.items) |c, char| {
            if (char == '[') {
                res += @as(u32, @intCast((r * 100 + c)));
            }
        }
    }
    print("{d}\n", .{res});
}

fn findAllMoving(
    allocator: Allocator,
    start_r: usize,
    start_c: usize,
    map: ArrayList(ArrayList(u8)),
    direction: Direction) !?ArrayList(Location) {

    var visited = AutoHashMap(Location, void).init(allocator);
    defer visited.deinit();

    var processing = AutoHashMap(Location, void).init(allocator);
    defer processing.deinit();

    const rows = map.items.len;
    const cols = map.items[0].items.len;

    const dir: usize = @intFromEnum(direction);

    var ret = ArrayList(Location).init(allocator);

    var stack = ArrayList(Location).init(allocator);
    defer stack.deinit();

    try stack.append(.{.r = start_r, .c = start_c});
    try visited.put(.{.r = start_r, .c = start_c}, {});

    while (stack.items.len != 0) {
        const l = stack.getLast();
        const r = l.r;
        const c = l.c;

        if (processing.get(l)) |_| {
            _ = stack.pop();
            _ = processing.remove(l);
            try ret.append(l);
            continue;
        }

        try processing.put(l, {});

        const next_r_i32 = @as(i32, @intCast(r)) + dr[dir];
        const next_c_i32 = @as(i32, @intCast(c)) + dc[dir];

        if (!inBounds(next_r_i32, next_c_i32, rows, cols)) {
            ret.deinit();
            return null;
        }

        const next_r: usize = @intCast(next_r_i32);
        const next_c: usize = @intCast(next_c_i32);

        if (map.items[next_r].items[next_c] == '#' or map.items[next_r].items[next_c + 1] == '#') {
            ret.deinit();
            return null;
        }

        if (map.items[next_r].items[next_c] == '[') {
            const next_location = Location {
                .r = next_r,
                .c = next_c,
            };
            if (!visited.contains(next_location)) {
                try visited.put(next_location, {});
                try stack.append(next_location);
            }
        } else if (map.items[next_r].items[next_c] == ']') {
            const next_location = Location {
                .r = next_r,
                .c = next_c - 1,
            };
            if (!visited.contains(next_location)) {
                try visited.put(next_location, {});
                try stack.append(next_location);
            }
        }

        if (map.items[next_r].items[next_c + 1] == '[') {
            const next_location = Location {
                .r = next_r,
                .c = next_c + 1,
            };
            if (!visited.contains(next_location)) {
                try visited.put(next_location, {});
                try stack.append(next_location);
            }
        }
    }

    return ret;
}
