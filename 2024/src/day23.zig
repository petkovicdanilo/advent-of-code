const std = @import("std");
const print = std.debug.print;
const ArrayList = std.ArrayList;
const StringHashMap = std.StringHashMap;
const Allocator = std.mem.Allocator;

const Input = StringHashMap(StringHashMap(void));

fn getInput(allocator: Allocator, file_name: []const u8) !Input {
    const file = try std.fs.cwd().openFile(file_name, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;

    var input = StringHashMap(StringHashMap(void)).init(allocator);

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line_buf| {
        if (line_buf.len == 0) {
            continue;
        }

        var it = std.mem.split(u8, line_buf, "-");

        const n1_tmp = it.next().?;
        const n1 = try allocator.alloc(u8, n1_tmp.len);
        @memcpy(n1, n1_tmp);

        const n2_tmp = it.next().?;
        const n2 = try allocator.alloc(u8, n2_tmp.len);
        @memcpy(n2, n2_tmp);

        if (input.getPtr(n1)) |adj_map| {
            try adj_map.*.put(n2, {});
        } else {
            var adj_map = StringHashMap(void).init(allocator);
            try adj_map.put(n2, {});
            try input.put(n1, adj_map);
        }

        if (input.getPtr(n2)) |adj_map| {
            try adj_map.*.put(n1, {});
        } else {
            var adj_map = StringHashMap(void).init(allocator);
            try adj_map.put(n1, {});
            try input.put(n2, adj_map);
        }
    }

    return input;
}

pub fn solvePartOne() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var input = try getInput(allocator, "examples/day23.txt");

    // var it = input.iterator();
    // while (it.next()) |kv| {
    //     const n = kv.key_ptr.*;
    //     const adj_map = kv.value_ptr.*;
    //     print("{s}: ", .{n});
    //     var it2 = adj_map.keyIterator();
    //     while (it2.next()) |k| {
    //         const n2 = k.*;
    //         print("{s} ", .{n2});
    //     }
    //     print("\n", .{});
    // }

    var visited = StringHashMap(void).init(allocator);
    defer visited.deinit();

    var res: u32 = 0;

    var it1 = input.iterator();
    while (it1.next()) |kv| {
        const n1 = kv.key_ptr.*;
        if (visited.contains(n1)) {
            continue;
        }

        const t1 = std.mem.startsWith(u8, n1, "t");

        var curr_res: u32 = 0;
        var visited_as_second = StringHashMap(void).init(allocator);
        defer visited_as_second.deinit();

        const adj_map = kv.value_ptr.*;
        var it2 = adj_map.keyIterator();
        while (it2.next()) |k2| {
            const n2 = k2.*;
            if (visited.contains(n2)) {
                continue;
            }
            
            try visited_as_second.put(n2, {});

            const t2 = std.mem.startsWith(u8, n2, "t");

            var it3 = adj_map.keyIterator();
            while (it3.next()) |k3| {
                const n3 = k3.*;
                if (std.mem.eql(u8, n2, n3)) {
                    continue;
                }

                const t3 = std.mem.startsWith(u8, n3, "t");

                if (visited.contains(n3) or visited_as_second.contains(n3)) {
                    continue;
                }

                if (!t1 and !t2 and !t3) {
                    continue;
                }

                if (input.get(n2)) |adj_map2| {
                    if(adj_map2.contains(n3)) {
                        curr_res += 1;
                    }
                }
            }
        }

        res += curr_res;

        try visited.put(n1, {});
    }

    print("{d}\n", .{res});

    var val_it = input.valueIterator();
    while (val_it.next()) |v| {
        v.*.deinit();
    }
    input.deinit();
}

pub fn solvePartTwo() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var input = try getInput(allocator, "examples/day23.txt");

    // var it = input.iterator();
    // while (it.next()) |kv| {
    //     const n = kv.key_ptr.*;
    //     const adj_map = kv.value_ptr.*;
    //     print("{s}: ", .{n});
    //     var it2 = adj_map.keyIterator();
    //     while (it2.next()) |k| {
    //         const n2 = k.*;
    //         print("{s} ", .{n2});
    //     }
    //     print("\n", .{});
    // }

    var visited = StringHashMap(void).init(allocator);
    defer visited.deinit();

    var curr_max = ArrayList([]const u8).init(allocator);

    var it = input.iterator();
    while (it.next()) |kv| {
        const n1 = kv.key_ptr.*;
        
        var adj_list = ArrayList([]const u8).init(allocator);
        defer adj_list.deinit();
        var adj_it = kv.value_ptr.*.keyIterator();
        while (adj_it.next()) |neighbour| {
            try adj_list.append(neighbour.*);
        }

        var curr_list = ArrayList([]const u8).init(allocator);
        defer curr_list.deinit();
        try curr_list.append(n1);

        const max_clique = try maxClique(
            allocator,
            &curr_list,
            adj_list.items[0..],
            input,
        );

        if (max_clique) |m| {
            if (m.items.len > curr_max.items.len) {
                curr_max.deinit();
                curr_max = m;
            }
        }
        try visited.put(n1, {});
    }

    
    std.mem.sort([]const u8, curr_max.items, {}, comptime stringCompare);

    for (0..curr_max.items.len, curr_max.items) |i, c| {
        print("{s}", .{c});
        if (i != curr_max.items.len - 1) {
            print(",", .{});
        } else {
            print("\n", .{});
        }
    }

    curr_max.deinit();
    var val_it = input.valueIterator();
    while (val_it.next()) |v| {
        v.*.deinit();
    }
    input.deinit();
}

fn maxClique(
    allocator: Allocator,    
    curr_list: *ArrayList([]const u8),
    to_process: [][]const u8,
    input: Input,
) !?ArrayList([]const u8) {
    if (to_process.len == 0) {
        var res = ArrayList([]const u8).init(allocator);
        for (curr_list.items) |c| {
            try res.append(c);
        }
        return res;
    }

    const neighbour = to_process[0];

    var res_with: ?ArrayList([]const u8) = null;
    var ok = true;
    for (curr_list.items) |curr| {
        if (!input.get(curr).?.contains(neighbour)) {
            ok = false;
            break;
        }
    }

    if (ok) {
        try curr_list.append(neighbour);
        res_with = try maxClique(allocator, curr_list, to_process[1..], input);
        _ =  curr_list.pop();
    }
    
    const res_without = try maxClique(allocator, curr_list, to_process[1..], input);

    if (res_with == null and res_without == null) {
        return null;
    }

    if (res_with == null) {
        return res_without;
    }

    if (res_without == null) {
        return res_with;
    }

    if (res_with.?.items.len >= res_without.?.items.len) {
        res_without.?.deinit();
        return res_with;
    }

    res_with.?.deinit();
    return res_without;
}

fn stringCompare(_: void, str1: []const u8, str2: []const u8) bool {
    const order = std.mem.order(u8, str1, str2);
    switch (order) {
        .lt => return true,
        .eq => return true,
        .gt => return false,
    }

    unreachable;
}
