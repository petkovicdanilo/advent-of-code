const std = @import("std");
const print = std.debug.print;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const AutoHashMap = std.AutoHashMap;
const Tuple = std.meta.Tuple;
const expectEqual = std.testing.expectEqual;

const Input = ArrayList(u128);

fn getInput(allocator: Allocator, file_name: []const u8) !Input {
    const file = try std.fs.cwd().openFile(file_name, .{});
    defer file.close();

    var input = ArrayList(u128).init(allocator);

    const file_buffer = try file.readToEndAlloc(allocator, 1024*1024);
    defer allocator.free(file_buffer);

    var it = std.mem.split(u8, file_buffer[0..file_buffer.len - 1], " ");
    while (it.next()) |num_str| {
        if (std.mem.eql(u8, num_str, "\n")) {
            break;
        }
        const num = try std.fmt.parseInt(u128, num_str, 10);
        try input.append(num);
    }

    return input;
}

pub fn solvePartOne() !void {
    try solve(comptime 25);
}

pub fn solvePartTwo() !void {
    try solve(comptime 75);
}

fn solve(comptime n: u32) !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const input = try getInput(allocator, "examples/day11.txt");
    defer input.deinit();

    var visited: [n + 1]AutoHashMap(u128, u128) = undefined;

    for (0..n + 1) |i| {
        visited[i] = AutoHashMap(u128, u128).init(allocator);
    }

    var res: u128 = 0;
    for (input.items) |el| {
        const sub_res = try blink(el, n, &visited[0..]);
        res += sub_res;
    }

    print("{d}\n", .{res});

    for (0..n) |i| {
        visited[i].deinit();
    }
}

fn blink(el: u128, steps: u8, visited: *const []AutoHashMap(u128, u128)) !u128 {
    // print("el = {d}, steps = {d}\n", .{el, steps});
    if (steps == 0) {
        try visited.*[steps].put(el, 1);
        return 1;
    }

    if (visited.*[steps].get(el)) |res_stones| {
        return res_stones;
    }

    // have to calculate
    if (el == 0) {
        const res = try blink(1, steps - 1, visited);
        try visited.*[steps].put(el, res);
        return res;
    }

    const num_digits = numDigits(el);
    if (num_digits % 2 == 0) {
        const half = @divExact(num_digits, 2);
        const t = splitAt(el, half);
        const left = t[0];
        const right = t[1];

        const left_res = try blink(left, steps - 1, visited);
        const right_res = try blink(right, steps - 1, visited);

        const res = left_res + right_res;
        try visited.*[steps].put(el, res);

        return res;
    }

    const res = try blink(el * 2024, steps - 1, visited);
    try visited.*[steps].put(el, res);
    return res;
}

fn numDigits(num: u128) u32 {
    if (num >= 0 and num <= 9) {
        return 1;
    }

    var pow: u128 = 10;
    var counter: u32 = 2;
    while (!(num >= pow and num <= pow * 10)) {
        pow *= 10;
        counter += 1;
    }

    return counter;
}

test "numDigits" {
    try expectEqual(3, numDigits(123));
    try expectEqual(4, numDigits(2024));
}

fn splitAt(num: u128, idx: u32) Tuple(&.{u128, u128}) {
    var num_tmp = num;
    var pow: u128 = 1;

    var right: u128 = 0;
    for (0..idx) |_| {
        const d = num_tmp % 10;
        right += (d * pow);
        pow *= 10;
        num_tmp = @divTrunc(num_tmp, 10);
    }

    const left = num_tmp;

    return .{
        left, right
    };
}

test "splitAt" {
    try expectEqual(.{12, 34}, splitAt(1234, 2));
    try expectEqual(.{20, 24}, splitAt(2024, 2));
    try expectEqual(.{210, 24}, splitAt(210024, 3));
    try expectEqual(.{2, 4}, splitAt(24, 1));
    try expectEqual(.{4, 0}, splitAt(40, 1));
}
