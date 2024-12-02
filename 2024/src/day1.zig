const std = @import("std");
const print = std.debug.print;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const ProblemInput = std.meta.Tuple(&.{ArrayList(u32), ArrayList(u32)});

pub fn solvePartOne() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const p = try parseInput(allocator);
    const first_list = p[0];
    const second_list = p[1];

    std.mem.sort(u32, first_list.items, {}, comptime std.sort.asc(u32));
    std.mem.sort(u32, second_list.items, {}, comptime std.sort.asc(u32));

    var res: u32 = 0;
    for (first_list.items, second_list.items) |first, second| {
        if (first >= second) {
            res += (first - second);
        } else {
            res += (second - first);
        }
    }

    print("{d}\n", .{res});
}

pub fn solvePartTwo() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const p = try parseInput(allocator);
    const first_list = p[0];
    const second_list = p[1];

    var count_map = std.AutoHashMap(u32, u32).init(allocator);
    defer count_map.deinit();

    for (second_list.items) |item| {
        const curr = count_map.get(item) orelse 0;
        try count_map.put(item, curr + 1);
    }
    

    var res: u32 = 0;
    for (first_list.items) |item| {
        const count = count_map.get(item) orelse 0;
        res += (item * count);
    }

    print("{d}\n", .{res});
}

fn parseInput(allocator: Allocator) !ProblemInput {
    const file = try std.fs.cwd().openFile("inputs/day1.txt", .{});
    defer file.close();

    var first_list = ArrayList(u32).init(allocator);
    var second_list = ArrayList(u32).init(allocator);

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var it = std.mem.split(u8, line, "   ");

        const first_str = it.next().?;
        const first = try std.fmt.parseInt(u32, first_str, 10);
        try first_list.append(first);

        const second_str = it.next().?;
        const second = try std.fmt.parseInt(u32, second_str, 10);
        try second_list.append(second);
    }
    
    return .{first_list, second_list};
}
