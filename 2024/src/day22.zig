const std = @import("std");
const print = std.debug.print;
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const Allocator = std.mem.Allocator;

const Input = ArrayList(u64);

fn getInput(allocator: Allocator, file_name: []const u8) !Input {
    const file = try std.fs.cwd().openFile(file_name, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;

    var input = Input.init(allocator);

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line_buf| {
        if (line_buf.len == 0) {
            continue;
        }

        const val = try std.fmt.parseInt(u64, line_buf, 10);
        try input.append(val);
    }

    return input;
}


pub fn solvePartOne() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var input = try getInput(allocator, "examples/day22.txt");
    defer input.deinit();

    const steps: u32 = 2000;

    for (input.items) |*number| {
        for (0..steps) |_| {
            number.* = nextSecretNumber(number.*);
        }
    }

    var res: u64 = 0;
    for (input.items) |*number| {
        res += number.*;
    }

    // for (input.items) |number| {
    //     print("{d} ", .{number});
    // }
    // print("\n", .{});

    print("{d}\n", .{res});
}

pub fn solvePartTwo() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var input = try getInput(allocator, "examples/day22.txt");
    defer input.deinit();

    var diff_list = ArrayList(ArrayList(i8)).init(allocator);
    for (input.items) |_| {
        try diff_list.append(ArrayList(i8).init(allocator));
    }

    var max_price = ArrayList(AutoHashMap([4]i8, u8)).init(allocator);
    for (input.items) |_| {
        try max_price.append(AutoHashMap([4]i8, u8).init(allocator));
    }

    const steps: u32 = 2000;

    for (0.., input.items) |i, *number| {
        for (0..steps) |_| {
            const nextNumber = nextSecretNumber(number.*);

            const diff: i8 = @as(i8, @intCast((nextNumber % 10))) - 
                            @as(i8, @intCast(number.* % 10));

            if (diff_list.items[i].items.len == 4) {
                _ = diff_list.items[i].orderedRemove(0);
            }
            try diff_list.items[i].append(diff);

            number.* = nextNumber;

            if (diff_list.items[i].items.len != 4) {
                continue;
            }

            if (max_price.items[i].contains(diff_list.items[i].items[0..4].*)) {
                continue;
            }

            var seq: [4]i8 = undefined;
            for (0..4) |j| {
                seq[j] = diff_list.items[i].items[j];
            }

            try max_price.items[i].put(seq, @as(u8, @intCast(nextNumber % 10)));
        }
    }

    var res: u64 = 0;
    for (0..19) |n1| {
        const num1: i8 = @as(i8, @intCast(n1)) - 9;
        for (0..19) |n2| {
            const num2: i8 = @as(i8, @intCast(n2)) - 9;
            for (0..19) |n3| {
                const num3: i8 = @as(i8, @intCast(n3)) - 9;
                for (0..19) |n4| {
                    const num4: i8 = @as(i8, @intCast(n4)) - 9;

                    var curr_res: u64 = 0;
                    for (max_price.items) |mp| {
                        if (!mp.contains(.{num1, num2, num3, num4})) {
                            continue;
                        }

                        curr_res += mp.get(.{num1, num2, num3, num4}).?;
                    }

                    res = @max(res, curr_res);
                }
            }
        }
    }

    print("{d}\n", .{res});

    for (diff_list.items) |diff| {
        diff.deinit();
    }
    diff_list.deinit();

    for (max_price.items) |*max_p| {
        max_p.deinit();
    }
    max_price.deinit();
}

fn nextSecretNumber(num: u64) u64 {
    const p1 = process1(num);
    const p2 = process2(p1);
    const p3 = process3(p2);
    return p3;
}

fn process1(num: u64) u64 {
    const res = num << 6;
    const tmp = num ^ res;

    const mask = (1 << 24) - 1;
    return tmp & mask;
}

fn process2(num: u64) u64 {
    const res = num >> 5;
    const tmp = num ^ res;

    const mask = (1 << 24) - 1;
    return tmp & mask;
}

fn process3(num: u64) u64 {
    const res = num << 11;
    const tmp = num ^ res;

    const mask = (1 << 24) - 1;
    return tmp & mask;
}

