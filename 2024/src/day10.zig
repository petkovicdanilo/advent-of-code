const std = @import("std");
const print = std.debug.print;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const AutoHashMap = std.AutoHashMap;

const dr = [_]i32{ -1, 0, 1,  0 };
const dc = [_]i32{  0, 1, 0, -1 };

const Input = ArrayList(ArrayList(u8));

const Position = struct {
    r: usize,
    c: usize,
};

fn getInput(allocator: Allocator, file_name: []const u8) !Input {
    const file = try std.fs.cwd().openFile(file_name, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;

    var input = ArrayList(ArrayList(u8)).init(allocator);

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line_buf| {
        var row = ArrayList(u8).init(allocator);
        for (0..line_buf.len) |i| {
            const num = try std.fmt.parseInt(u8, line_buf[i..i+1], 10);
            try row.append(num);
        }
        try input.append(row);
    }

    return input;
}

pub fn solvePartOne() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const input = try getInput(allocator, "examples/day10.txt");

    var visited = AutoHashMap(Position, AutoHashMap(Position, void)).init(allocator);

    // every nine is reachable from itself
    for (0.., input.items) |r, row| {
        for (0.., row.items) |c, num| {
            if (num != 9) {
                continue;
            }

            var reachable_nines = AutoHashMap(Position, void).init(allocator);
            try reachable_nines.put(.{.r = r, .c = c}, {});
            try visited.put(.{.r = r, .c = c}, reachable_nines);
        }
    }

    var res: u32 = 0;

    for (0.., input.items) |r, row| {
        for (0.., row.items) |c, num| {
            if (num != 0) {
                continue;
            }

            try findTrailheadsFrom(allocator, r, c, input, &visited);
            res += visited.get(.{.r = r, .c = c}).?.count();
        }
    }

    print("{d}\n", .{res});

    var visited_it = visited.iterator();
    while (visited_it.next()) |kv| {
        kv.value_ptr.*.deinit();
    }
    visited.deinit();

    for (input.items) |row| {
        row.deinit();
    }
    input.deinit();
}

fn findTrailheadsFrom(
    allocator: Allocator,
    r: usize,
    c: usize,
    matrix: ArrayList(ArrayList(u8)),
    visited: *AutoHashMap(Position, AutoHashMap(Position, void))) !void {

    const curr_num = matrix.items[r].items[c];

    const num_rows = matrix.items.len;
    const num_cols = matrix.items[0].items.len;

    var reachable_nines = AutoHashMap(Position, void).init(allocator);

    for (0..4) |dir| {
        const neighbour_r_i32 = @as(i32, @intCast(r)) + dr[dir];
        const neighbour_c_i32 = @as(i32, @intCast(c)) + dc[dir];

        if (!inBounds(neighbour_r_i32, neighbour_c_i32, num_rows, num_cols)) {
            continue;
        }

        const neighbour_r = @as(usize, @intCast(neighbour_r_i32));
        const neighbour_c = @as(usize, @intCast(neighbour_c_i32));

        if (matrix.items[neighbour_r].items[neighbour_c] != curr_num + 1) {
            continue;
        }

        const neighbour_reachable_nines_opt = visited.get(.{
            .r = neighbour_r,
            .c = neighbour_c
        });
        if (neighbour_reachable_nines_opt == null) {
            try findTrailheadsFrom(allocator, neighbour_r, neighbour_c, matrix, visited);
        }

        const neighbour_reachable_nines = visited.get(.{
            .r = neighbour_r,
            .c = neighbour_c
        }).?;

        var neigbour_it = neighbour_reachable_nines.keyIterator();
        while (neigbour_it.next()) |position| {
            try reachable_nines.put(position.*, {});
        }
    }
    try visited.put(.{.r = r, .c = c}, reachable_nines);
}

pub fn solvePartTwo() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const input = try getInput(allocator, "examples/day10.txt");

    var trailhead_matrix = ArrayList(ArrayList(u32)).init(allocator);
    for (input.items) |input_row| {
        var row = try ArrayList(u32).initCapacity(allocator, input_row.items.len);
        for (input.items[0].items) |_| {
            try row.append(0);
        }
        try trailhead_matrix.append(row);
    }

    var res: u32 = 0;

    const num_rows = input.items.len;
    const num_cols = input.items[0].items.len;

    var curr_num: i32 = 9;
    while (curr_num >= 0) {
        for (0.., input.items) |r, row| {
            for (0.., row.items) |c, num| {
                if (num != curr_num) {
                    continue;
                }

                if (num == 9) {
                    trailhead_matrix.items[r].items[c] = 1;
                    continue;
                }

                for (0..4) |dir| {
                    const neighbour_r_i32 = @as(i32, @intCast(r)) + dr[dir];
                    const neighbour_c_i32 = @as(i32, @intCast(c)) + dc[dir];

                    if (!inBounds(neighbour_r_i32, neighbour_c_i32, num_rows, num_cols)) {
                        continue;
                    }

                    const neighbour_r = @as(usize, @intCast(neighbour_r_i32));
                    const neighbour_c = @as(usize, @intCast(neighbour_c_i32));

                    if (input.items[neighbour_r].items[neighbour_c] == curr_num + 1) {
                        trailhead_matrix.items[r].items[c] += 
                                trailhead_matrix.items[neighbour_r].items[neighbour_c];
                    }
                }
            }
        }

        curr_num -= 1;
    }

    for (0.., input.items) |r, row| {
        for (0.., row.items) |c, num| {
            if (num != 0) {
                continue;
            }
            res += trailhead_matrix.items[r].items[c];
        }
    }

    // for (input.items) |row| {
    //     for (row.items) |val| {
    //         print("{d: <3} ", .{val});
    //     }
    //     print("\n", .{});
    // }
    // print("\n", .{});
    //
    // for (trailhead_matrix.items) |row| {
    //     for (row.items) |val| {
    //         print("{d: <3} ", .{val});
    //     }
    //     print("\n", .{});
    // }
    // print("\n", .{});
    //

    print("{d}\n", .{res});

    for (input.items) |row| {
        row.deinit();
    }
    input.deinit();

    for (trailhead_matrix.items) |row| {
        row.deinit();
    }
    trailhead_matrix.deinit();
}

fn inBounds(r: i32, c: i32, rows: usize, cols: usize) bool {
    const rows_i32 = @as(i32, @intCast(rows));
    const cols_i32 = @as(i32, @intCast(cols));

    return (r >= 0 and r < rows_i32 and c >= 0 and c < cols_i32);
}

