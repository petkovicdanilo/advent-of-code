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

    var input = try getInput(allocator, "examples/day22-2.txt");
    defer input.deinit();

    var max_bananas = AutoHashMap([4]i8, u32).init(allocator);
    defer max_bananas.deinit();

    const steps: u32 = 2000;

    for (input.items) |*number| {
        var diff_list = ArrayList(i8).init(allocator);
        defer diff_list.deinit();

        var sequences_found = AutoHashMap([4]i8, void).init(allocator);
        defer sequences_found.deinit();

        for (0..steps) |_| {
            const nextNumber = nextSecretNumber(number.*);

            const diff: i8 = @as(i8, @intCast((nextNumber % 10))) - 
                            @as(i8, @intCast(number.* % 10));

            if (diff_list.items.len == 4) {
                _ = diff_list.orderedRemove(0);
            }
            try diff_list.append(diff);

            number.* = nextNumber;

            if (diff_list.items.len != 4) {
                continue;
            }

            var seq: [4]i8 = undefined;
            for (0..4) |i| {
                seq[i] = diff_list.items[i];
            }

            if (sequences_found.contains(seq)) {
                continue;
            }

            try sequences_found.put(seq, {});

            const curr = max_bananas.get(seq) orelse 0;
            try max_bananas.put(seq, curr + @as(u32, @intCast(nextNumber % 10)));
        }
    }

    var res: u32 = 0;
    var it = max_bananas.iterator();
    while (it.next()) |kv| {
        res = @max(res, kv.value_ptr.*);
    }

    print("{d}\n", .{res});
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

