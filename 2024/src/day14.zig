const std = @import("std");
const print = std.debug.print;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const Robot = struct {
    r: i32,
    c: i32,
    v_r: i32,
    v_c: i32,
};

fn getInput(allocator: Allocator, file_name: []const u8) !ArrayList(Robot) {
    const file = try std.fs.cwd().openFile(file_name, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;

    var robots = ArrayList(Robot).init(allocator);

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line_buf| {
        var it = std.mem.split(u8, line_buf, " ");

        const p_str = it.next().?[2..];
        var p_it = std.mem.split(u8, p_str, ",");
        const c = try std.fmt.parseInt(i32, p_it.next().?, 10);
        const r = try std.fmt.parseInt(i32, p_it.next().?, 10);

        const v_str = it.next().?[2..];
        var v_it = std.mem.split(u8, v_str, ",");
        const v_c = try std.fmt.parseInt(i32, v_it.next().?, 10);
        const v_r = try std.fmt.parseInt(i32, v_it.next().?, 10);
        
        try robots.append(.{
            .r = r,
            .c = c,
            .v_r = v_r,
            .v_c = v_c,
        });
    }

    return robots;
}

pub fn solvePartOne() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const robots = try getInput(allocator, "examples/day14.txt");
    defer robots.deinit();

    const rows = 103;
    const cols = 101;

    // const rows = 7;
    // const cols = 11;

    const steps = 100;

    var quadrants = [4]u32 {0, 0, 0, 0};

    for (robots.items) |robot| {
        var end_r: i32 = @rem(robot.r + steps * robot.v_r, rows);
        if (end_r < 0) {
            end_r += rows;
        }

        var end_c: i32 = @rem(robot.c + steps * robot.v_c, cols);
        if (end_c < 0) {
            end_c += cols;
        }

        // print("({d} {d}) going {d} {d} ends up at ({d}, {d})\n", .{
        //     robot.r, robot.c, robot.v_r, robot.v_c, end_r, end_c,
        // });

        const mid_r = @divExact(rows - 1, 2);
        const mid_c = @divExact(cols - 1, 2);

        if (end_r < mid_r and end_c < mid_c) {
            // top-left
            quadrants[0] += 1;
        } else if (end_r < mid_r and end_c > mid_c) {
            // top-right
            quadrants[1] += 1;
        } else if (end_r > mid_r and end_c < mid_c) {
            // bottom-left
            quadrants[2] += 1;
        } else if (end_r > mid_r and end_c > mid_c) {
            // bottom-right
            quadrants[3] += 1;
        }
    }

    // print("{d} {d} {d} {d}\n", .{quadrants[0], quadrants[1], quadrants[2], quadrants[3]});

    const res: u64 = quadrants[0] * quadrants[1] * quadrants[2] * quadrants[3];
    print("{d}\n", .{res});
}

pub fn solvePartTwo() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const robots = try getInput(allocator, "examples/day14.txt");
    defer robots.deinit();

    const rows: usize = 103;
    const cols: usize = 101;

    const rows_i32: i32 = @intCast(rows);
    const cols_i32: i32 = @intCast(cols);

    var steps: u32 = 0;
    var found = false;

    // max consecutive slots to be occupied to be considered as solution
    const row_threshold: u32 = 30;

    while (!found) {
        var tile_count: [rows][cols]u32 = undefined;
        for (0..rows) |r| {
            for (0..cols) |c| {
                tile_count[r][c] = 0;
            }
        }

        for (robots.items) |robot| {
            var end_r: i32 = @rem(
                    robot.r + @as(i32, @intCast(steps)) * robot.v_r,
                    rows_i32
            );
            if (end_r < 0) {
                end_r += rows_i32;
            }

            var end_c: i32 = @rem(
                robot.c + @as(i32, @intCast(steps)) * robot.v_c,
                cols_i32
            );
            if (end_c < 0) {
                end_c += cols_i32;
            }

            tile_count[@as(usize, @intCast(end_r))][@as(usize, @intCast(end_c))] += 1;
        }

        var running_max_in_row: u32 = 0;
        var max: u32 = 0;
        for (0..rows) |r| {
            running_max_in_row = 0;
            for (0..cols) |c| {
                if (tile_count[r][c] != 0) {
                    running_max_in_row += 1;
                } else {
                    if (running_max_in_row > max) {
                        max = running_max_in_row;
                    }
                    running_max_in_row = 0;
                }
            }
        }

        if (max > row_threshold) {
            found = true;
            // print("step {d}\n", .{steps});
            // print("===============================================\n", .{});
            // for (0..rows) |r| {
            //     for (0..cols) |c| {
            //         if (tile_count[r][c] > 0) {
            //             print("x", .{});
            //         } else {
            //             print(" ", .{});
            //         }
            //     }
            //     print("\n", .{});
            // }
            // print("===============================================\n", .{});
            // print("\n", .{});
        } else {
            steps += 1;
        }
    }

    print("{d}\n", .{steps});
}
