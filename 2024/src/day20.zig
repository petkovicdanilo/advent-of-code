const std = @import("std");
const print = std.debug.print;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const AutoHashMap = std.AutoHashMap;
const PriorityQueue = std.PriorityQueue;

const dr = [_]i32{ -1, 0, 1,  0 };
const dc = [_]i32{  0, 1, 0, -1 };

const Location = struct {
    r: usize,
    c: usize,
};

const Cheat = struct {
    start: Location,
    end: Location,
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

pub fn solvePartOne() !void {
    // example
    const MIN_DIST_SAVE = 64;
    // input
    // const MIN_DIST_SAVE = 100;

    const MAX_CHEAT_DIST = 2;

    try solve(MAX_CHEAT_DIST, MIN_DIST_SAVE, "examples/day20.txt");
}

pub fn solvePartTwo() !void {
    // example
    const MIN_DIST_SAVE = 50;
    // input
    // const MIN_DIST_SAVE = 100;

    const MAX_CHEAT_DIST = 20;

    try solve(MAX_CHEAT_DIST, MIN_DIST_SAVE, "examples/day20.txt");
}

fn solve(comptime max_cheat_dist: u32, comptime min_dist_save: u32, file_name: []const u8) !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var input = try Input.init(allocator, file_name);
    defer input.deinit();

    const rows = input.map.items.len;
    const cols = input.map.items[0].items.len;

    var locations = ArrayList(Location).init(allocator);
    defer locations.deinit();

    var visited = AutoHashMap(Location, void).init(allocator);
    defer visited.deinit();

    var r = input.start_r;
    var c = input.start_c;

    while (!(r == input.end_r and c == input.end_c)) {
        try locations.append(.{.r = r, .c = c});
        try visited.put(.{.r = r, .c = c}, {});

        for (0..4) |dir| {
            const next_r_i32 = @as(i32, @intCast(r)) + dr[dir];
            const next_c_i32 = @as(i32, @intCast(c)) + dc[dir];

            if (!inBounds(next_r_i32, next_c_i32, rows, cols)) {
                continue;
            }

            const next_r: usize = @intCast(next_r_i32);
            const next_c: usize = @intCast(next_c_i32);

            if (input.map.items[next_r].items[next_c] == '#') {
                continue;
            }

            if (visited.contains(.{.r = next_r, .c = next_c})) {
                continue;
            }

            r = next_r;
            c = next_c;

            break;
        }
    }
    try locations.append(.{.r = input.end_r, .c = input.end_c});

    var cheats = AutoHashMap(Cheat, void).init(allocator);
    defer cheats.deinit();

    var res: u32 = 0;

    const end_dist = locations.items.len - 1;
    for (0..end_dist) |i| {
        for (i + 1..end_dist + 1) |next| {
            if (cheats.contains(.{
                .start = locations.items[i],
                .end = locations.items[next]
            })) {
                continue;
            }

            const d = manhattanDistance(locations.items[i], locations.items[next]);
            if (d > max_cheat_dist) {
                continue;
            }

            const new_dist = i + d + (end_dist - next);

            if (new_dist < end_dist and end_dist - new_dist >= min_dist_save) {
                res += 1;
                try cheats.put(.{
                    .start = locations.items[i],
                    .end = locations.items[next]
                }, {});
            }
        }
    }

    print("{d}\n", .{res});
}

fn manhattanDistance(l1: Location, l2: Location) u32 {
    return 
    @abs(
        @as(i32, @intCast(l1.r)) - @as(i32, @intCast(l2.r))
    ) + 
    @abs(
        @as(i32, @intCast(l1.c)) - @as(i32, @intCast(l2.c))
    );
}
