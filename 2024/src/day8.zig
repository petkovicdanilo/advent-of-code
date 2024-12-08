const std = @import("std");
const print = std.debug.print;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const AutoHashMap = std.AutoHashMap;

const Point = struct {
    r: usize,
    c: usize
};

const UnsafePoint = struct {
    r: i32,
    c: i32,
};


const Input = struct {
    antennas: AutoHashMap(u8, ArrayList(Point)),
    rows: usize,
    cols: usize,

    const Self = @This();

    fn init(allocator: Allocator, file_name: []const u8) !Self {
        const file = try std.fs.cwd().openFile(file_name, .{});
        defer file.close();

        var buf_reader = std.io.bufferedReader(file.reader());
        var in_stream = buf_reader.reader();
        var buf: [1024]u8 = undefined;

        var antennas = AutoHashMap(u8, ArrayList(Point)).init(allocator);
        var r: usize = 0;
        var cols: usize = 0;

        while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line_buf| {
            if (cols == 0) {
                cols = line_buf.len;
            }

            for (0.., line_buf) |c, char| {
                if (char == '.') {
                    continue;
                }

                const point = Point {
                    .r = r,
                    .c = c,
                };

                var char_antennas = antennas.get(char);
                if (char_antennas != null) {
                    try char_antennas.?.append(point);
                    try antennas.put(char, char_antennas.?);
                } else {
                    var new_char_antennas = ArrayList(Point).init(allocator);
                    try new_char_antennas.append(point);
                    try antennas.put(char, new_char_antennas);
                }
            }

            r += 1;
        }

        return .{
            .antennas = antennas,
            .rows = r,
            .cols = cols,
        };
    }

    pub fn deinit(self: *Self) void {
        var antenna_list_it = self.*.antennas.valueIterator();
        while (antenna_list_it.next()) |antenna_list| {
            antenna_list.*.deinit();
        }

        self.*.antennas.deinit();
    }
};

pub fn solvePartOne() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var input = try Input.init(allocator, "examples/day8.txt");
    defer input.deinit();

    // print("rows = {d}, cols = {d}\n", .{input.rows, input.cols});
    
    var antinodes = AutoHashMap(Point, void).init(allocator);
    defer antinodes.deinit();

    var antennas_list_it = input.antennas.valueIterator();
    while (antennas_list_it.next()) |antenna_list| {
        for (0.., antenna_list.*.items) |i, antenna1| {
            for (0.., antenna_list.*.items) |j, antenna2| {
                if (i == j) {
                    continue;
                }

                const antinode1 = findAntinode(antenna2, antenna1);
                // print("Antinode so that ({d}, {d}) is between it and ({d}, {d}) is ({d}, {d})\n", .{
                //     antenna1.r, antenna1.c,
                //     antenna2.r, antenna2.c,
                //     antinode1.r, antinode1.c
                // });
                if (inBounds(antinode1, input.rows, input.cols)) {
                    const p = Point {
                        .r = @as(usize, @intCast(antinode1.r)),
                        .c = @as(usize, @intCast(antinode1.c)),
                    };
                    if (!antinodes.contains(p)) {
                        // print("putting ({d}, {d})\n", .{p.r, p.c});
                        try antinodes.put(p, {});
                    }
                }

                const antinode2 = findAntinode(antenna1, antenna2);
                // print("Antinode so that ({d}, {d}) is between it and ({d}, {d}) is ({d}, {d})\n", .{
                //     antenna2.r, antenna2.c,
                //     antenna1.r, antenna1.c,
                //     antinode2.r, antinode2.c
                // });
                if (inBounds(antinode2, input.rows, input.cols)) {
                    const p = Point {
                        .r = @as(usize, @intCast(antinode2.r)),
                        .c = @as(usize, @intCast(antinode2.c)),
                    };
                    if (!antinodes.contains(p)) {
                        // print("putting ({d}, {d})\n", .{p.r, p.c});
                        try antinodes.put(p, {});
                    }
                }
            }
        }
    }

    print("{d}\n", .{antinodes.count()});
}

pub fn solvePartTwo() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var input = try Input.init(allocator, "examples/day8.txt");
    defer input.deinit();

    // print("rows = {d}, cols = {d}\n", .{input.rows, input.cols});
    
    var antinodes = AutoHashMap(Point, void).init(allocator);
    defer antinodes.deinit();

    var antennas_list_it = input.antennas.valueIterator();
    while (antennas_list_it.next()) |antenna_list| {
        for (0.., antenna_list.*.items) |i, antenna1| {
            for (0.., antenna_list.*.items) |j, antenna2| {
                if (i == j) {
                    continue;
                }

                var min_increment = findMinIncrement(antenna2, antenna1);
                // search in one direction.
                var curr = UnsafePoint{
                    .r = @as(i32, @intCast(antenna1.r)),
                    .c = @as(i32, @intCast(antenna1.c)),
                };

                while (inBounds(curr, input.rows, input.cols)) {
                    const p = Point {
                        .r = @as(usize, @intCast(curr.r)),
                        .c = @as(usize, @intCast(curr.c)),
                    };
                    if (!antinodes.contains(p)) {
                        // print("putting ({d}, {d})\n", .{p.r, p.c});
                        try antinodes.put(p, {});
                    
                    }

                    curr.r += min_increment.r;
                    curr.c += min_increment.c;
                }

                // search in opposite direction.
                min_increment.r = -min_increment.r;
                min_increment.c = -min_increment.c;

                curr = UnsafePoint{
                    .r = @as(i32, @intCast(antenna2.r)),
                    .c = @as(i32, @intCast(antenna2.c)),
                };

                while (inBounds(curr, input.rows, input.cols)) {
                    const p = Point {
                        .r = @as(usize, @intCast(curr.r)),
                        .c = @as(usize, @intCast(curr.c)),
                    };
                    if (!antinodes.contains(p)) {
                        // print("putting ({d}, {d})\n", .{p.r, p.c});
                        try antinodes.put(p, {});
                    
                    }

                    curr.r += min_increment.r;
                    curr.c += min_increment.c;
                }
            }
        }
    }

    print("{d}\n", .{antinodes.count()});
}

// find antinode so that the distance between start and mid will be the same as
// distance between antinode and mid.
fn findAntinode(start: Point, mid: Point) UnsafePoint {
    const u_start = UnsafePoint {
        .r = @as(i32, @intCast(start.r)),
        .c = @as(i32, @intCast(start.c)),
    };
    
    const u_mid = UnsafePoint {
        .r = @as(i32, @intCast(mid.r)),
        .c = @as(i32, @intCast(mid.c)),
    };

    const dist_r = u_mid.r - u_start.r;
    const dist_c = u_mid.c - u_start.c;
    
    return UnsafePoint {
        .r = u_start.r + 2*dist_r,
        .c = u_start.c + 2*dist_c,
    };
}

fn inBounds(unsafe_point: UnsafePoint, rows: usize, cols: usize) bool {
    const rows_i32 = @as(i32, @intCast(rows));
    const cols_i32 = @as(i32, @intCast(cols));

    return (unsafe_point.r >= 0 and unsafe_point.r < rows_i32 and
            unsafe_point.c >= 0 and unsafe_point.c < cols_i32);
}

fn findMinIncrement(start: Point, mid: Point) UnsafePoint {
    const u_start = UnsafePoint {
        .r = @as(i32, @intCast(start.r)),
        .c = @as(i32, @intCast(start.c)),
    };
    
    const u_mid = UnsafePoint {
        .r = @as(i32, @intCast(mid.r)),
        .c = @as(i32, @intCast(mid.c)),
    };

    const dist_r = u_mid.r - u_start.r;
    const dist_c = u_mid.c - u_start.c;

    if (dist_r == 0 or dist_c == 0) {
        return .{
            .r = dist_r,
            .c = dist_c,
        };
    }
    
    const gcd = @as(i32, @intCast(std.math.gcd(@abs(dist_r), @abs(dist_c))));

    return .{
        .r = @divExact(dist_r, gcd),
        .c = @divExact(dist_c, gcd),
    };
}
