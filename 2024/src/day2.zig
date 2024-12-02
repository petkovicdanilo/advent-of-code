const std = @import("std");
const print = std.debug.print;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const ProblemInput = ArrayList(ArrayList(i32));

pub fn solvePartOne() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const report_list = try parseInput(allocator);

    var num_safe: u32 = 0;

    for (report_list.items) |report| {
        const safe = try isReportSafe(report.items);
        if (safe) {
            num_safe += 1;
        }
    }
    print("{d}\n", .{num_safe});
}

pub fn solvePartTwo() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const report_list = try parseInput(allocator);

    var num_safe: u32 = 0;
    for (report_list.items) |report| {
        const safe = try isReportOneFromSafe(report.items);
        if (safe) {
            num_safe += 1;
        }
    }
    print("{d}\n", .{num_safe});
}

fn conflict(val1: i32, val2: i32, sign: i32) bool {
    const diff = val1 - val2;
    if (signOf(diff) != sign or @abs(diff) < 1 or @abs(diff) > 3) {
        return true;
    }
    return false;
}

fn isReportOneFromSafe(report: []i32) !bool {
    if (report.len < 2) {
        return true;
    }

    const sign = signOf(report[0] - report[1]);
    if (sign == 0) {
        return isReportSafe(report[1..]);
    }

    const l = report.len;
    for (1..l) |curr_index| {
        const prev_index = curr_index - 1;

        if (!conflict(report[prev_index], report[curr_index], sign)) {
            continue;
        }

        // we can remove either prev or current
        // we remove prev
        var can_remove_prev: bool = undefined;
        switch (prev_index) {
            0 => {
                // sign can change when removing element at the index 0.
                can_remove_prev = try isReportSafe(report[1..]);
            },
            1 => {
                // sign can change when removing element at the index 1.
                const new_sign = signOf(report[0] - report[2]);
                if (new_sign == 0) {
                    can_remove_prev = false;
                }
                else {
                    if (conflict(report[0], report[2], new_sign)) {
                        can_remove_prev = false;
                    } else {
                        can_remove_prev = try isReportSafeWithSign(report[2..], new_sign);
                    }
                }

                // Maybe the sign starting from the first two elements is not
                // correct. Try to remove first element.
                if (!can_remove_prev) {
                    can_remove_prev = try isReportSafe(report[1..]);
                }
            },
            else => {
                if (conflict(report[prev_index - 1], report[curr_index], sign)) {
                    can_remove_prev = false;
                } else {
                    can_remove_prev = try isReportSafeWithSign(report[curr_index..], sign);
                }
            }
        }

        if (can_remove_prev) {
            return true;
        }

        // we remove curr
        var can_remove_curr: bool = undefined;
        if (curr_index == l - 1) {
            return true;
        }

        switch (curr_index) {
            1 => {
                // sign can change when removing element at the index 1.
                const new_sign = signOf(report[0] - report[2]);
                if (new_sign == 0) {
                    return false;
                }
                if(conflict(report[0], report[2], new_sign)) {
                    return false;
                }
                can_remove_curr = try isReportSafeWithSign(report[2..], new_sign);
            },
            else => {
                if (conflict(report[prev_index], report[curr_index + 1], sign)) {
                    return false;
                }
                can_remove_curr = try isReportSafeWithSign(report[curr_index + 1..], sign);
            }
        }

        return can_remove_curr;
    }

    return true;
}

fn signOf(num: i32) i32 {
    if (num == 0) {
        return 0;
    }
    if (num < 0) {
        return -1;
    }
    return 1;
}

fn isReportSafe(report: []i32) !bool {
    if (report.len < 2) {
        return true;
    }

    const sign = signOf(report[0] - report[1]);
    if (sign == 0) {
        return false;
    }

    return try isReportSafeWithSign(report, sign);
}

fn isReportSafeWithSign(report: []i32, sign: i32) !bool {
    if (report.len < 2) {
        return true;
    }

    var prev: i32 = 0;
    var curr: i32 = report[0];

    const l = report.len;
    for (1..l) |i| {
        prev = curr;
        curr = report[i];

        if (conflict(prev, curr, sign)) {
            return false;
        }
    }

    return true;
}

fn parseInput(allocator: Allocator) !ProblemInput {
    const file = try std.fs.cwd().openFile("examples/day2.txt", .{});
    defer file.close();

    var input = ArrayList(ArrayList(i32)).init(allocator);

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var report = ArrayList(i32).init(allocator);
        var it = std.mem.split(u8, line, " ");

        while (it.next()) |i| {
            const str_val = i;
            const val = try std.fmt.parseInt(i32, str_val, 10);
            try report.append(val);
        }

        try input.append(report);
    }

    return input;
}
