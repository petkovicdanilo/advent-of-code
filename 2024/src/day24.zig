const std = @import("std");
const print = std.debug.print;
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const Allocator = std.mem.Allocator;
const StringHashMap = std.StringHashMap;

const Op = enum {
    AND,
    OR,
    XOR,
};

fn parseOp(s: []const u8) Op {
    if (std.mem.eql(u8, s, "AND")) {
        return Op.AND;
    }

    if (std.mem.eql(u8, s, "OR")) {
        return Op.OR;
    }

    if (std.mem.eql(u8, s, "XOR")) {
        return Op.XOR;
    }

    unreachable;
}

const WireRule = struct {
    input1: []const u8,
    input2: []const u8,
    op: Op,
};


const Wire = struct {
    rule: ?WireRule,
    value: ?u1,
};

const Input = struct {
    allocator: Allocator,
    wires_map: StringHashMap(Wire),

    const Self = @This();

    fn init(allocator: Allocator, file_name: []const u8) !Self {
        const file = try std.fs.cwd().openFile(file_name, .{});
        defer file.close();

        var buf_reader = std.io.bufferedReader(file.reader());
        var in_stream = buf_reader.reader();
        var buf: [1024]u8 = undefined;

        var wires_map = StringHashMap(Wire).init(allocator);

        var parse_header = true;

        while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line_buf| {
            if (std.mem.eql(u8, line_buf, "")) {
                parse_header = false;
                continue;
            }

            if (parse_header) {
                var it = std.mem.split(u8, line_buf, ": ");

                const wire = it.next().?;
                const w = try allocator.alloc(u8, wire.len);
                @memcpy(w, wire);

                const val = try std.fmt.parseInt(u1, it.next().?, 2);

                try wires_map.put(w, .{.value = val, .rule = null});
            } else {
                var it = std.mem.split(u8, line_buf, " ");

                const wire1 = it.next().?;
                const w1 = try allocator.alloc(u8, wire1.len);
                @memcpy(w1, wire1);

                const op = parseOp(it.next().?);

                const wire2 = it.next().?;
                const w2 = try allocator.alloc(u8, wire2.len);
                @memcpy(w2, wire2);

                // ignore ->
                _ = it.next().?;

                const res = it.next().?;
                const r = try allocator.alloc(u8, res.len);
                @memcpy(r, res);

                try wires_map.put(r, .{
                    .value = null,
                    .rule = .{
                        .input1 = w1,
                        .input2 = w2,
                        .op = op,
                    }
                });
            }
        }

        return .{
            .allocator = allocator,
            .wires_map = wires_map,
        };
    }

    fn deinit(self: *Self) void {
        var it = self.*.wires_map.iterator();
        while (it.next()) |kv| {
            self.*.allocator.free(kv.key_ptr.*);
            const wire = kv.value_ptr.*;

            if (wire.rule) |rule| {
                self.*.allocator.free(rule.input1);
                self.*.allocator.free(rule.input2);
            }
        }
        self.*.wires_map.deinit();
    }
};

fn stringCompare(_: void, str1: []const u8, str2: []const u8) bool {
    const order = std.mem.order(u8, str1, str2);
    switch (order) {
        .lt => return true,
        .eq => return true,
        .gt => return false,
    }

    unreachable;
}

pub fn solvePartOne() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var input = try Input.init(allocator, "examples/day24.txt");
    defer input.deinit();

    // var it = input.wires_map.iterator();
    // while (it.next()) |kv| {
    //     print("{s} = ", .{kv.key_ptr.*});
    //
    //     if (kv.value_ptr.*.rule) |rule| {
    //         print("{s} {any} {s}\n", .{rule.input1, rule.op, rule.input2});
    //     }
    //
    //     if (kv.value_ptr.*.value) |value| {
    //         print("{d}\n", .{value});
    //     }
    // }

    var z_values = ArrayList([]const u8).init(allocator);
    defer z_values.deinit();

    var it = input.wires_map.keyIterator();
    while (it.next()) |k| {
        if (k.*[0] == 'z') {
            try z_values.append(k.*);
        }
    }

    std.mem.sort([]const u8, z_values.items, {}, comptime stringCompare);

    var res: u64 = 0;
    var counter: u6 = 0;

    for (z_values.items) |z| {
        try calculate(allocator, z, &input.wires_map);
        const z_val = input.wires_map.get(z).?.value.?;
        // print("{s}: {d}\n", .{z, z_val});
        res = res | (@as(u64, @intCast(z_val)) << counter);
        counter += 1;
    }

    print("{d}\n", .{res});
}

pub fn solvePartTwo() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    // no example is suitable for analysis.
    var input = try Input.init(allocator, "inputs/day24.txt");
    defer input.deinit();

    // var it = input.wires_map.iterator();
    // while (it.next()) |kv| {
    //     print("{s} = ", .{kv.key_ptr.*});
    //
    //     if (kv.value_ptr.*.rule) |rule| {
    //         print("{s} {any} {s}\n", .{rule.input1, rule.op, rule.input2});
    //     }
    //
    //     if (kv.value_ptr.*.value) |value| {
    //         print("{d}\n", .{value});
    //     }
    // }

    var z_values = ArrayList([]const u8).init(allocator);
    defer z_values.deinit();

    var wrong = StringHashMap(void).init(allocator);
    defer wrong.deinit();

    var count_map = StringHashMap(u8).init(allocator);
    defer count_map.deinit();

    // reference https://www.geeksforgeeks.org/binary-adder-with-logic-gates/
    var it = input.wires_map.iterator();
    while (it.next()) |kv| {
        const res = kv.key_ptr.*;
        const wire = kv.value_ptr.*;

        if (wire.rule) |rule| {
            const input1 = rule.input1;
            const input2 = rule.input2;

            if (input1[0] != 'x' and input1[0] != 'y') {
                if (count_map.getPtr(input1)) |val| {
                    val.* += 1;
                } else {
                    try count_map.put(input1, 1);
                }
            }

            if (input2[0] != 'x' and input2[0] != 'y') {
                if (count_map.getPtr(input2)) |val| {
                    val.* += 1;
                } else {
                    try count_map.put(input2, 1);
                }
            }

            if (rule.op != Op.XOR) {
                if (res[0] == 'z') {
                    try wrong.put(res, {});
                }
            }

            if (rule.op == Op.XOR) {
                if ((input1[0] != 'x' and input1[0] != 'y') and
                    (input2[0] != 'x' and input2[0] != 'y') and
                    res[0] != 'z') {

                    try wrong.put(res, {});
                }
            }

            if (rule.op == Op.OR) {
                const wire1 = input.wires_map.get(input1).?;
                if (wire1.rule == null or wire1.rule.?.op != Op.AND) {
                    try wrong.put(input1, {});
                }

                const wire2 = input.wires_map.get(input2).?;
                if (wire2.rule == null or wire2.rule.?.op != Op.AND) {
                    try wrong.put(input2, {});
                }
            }
        }
    }

    var count_it = count_map.iterator();
    while (count_it.next()) |kv| {
        if (kv.value_ptr.* != 2) {
            continue;
        }

        if (input.wires_map.get(kv.key_ptr.*)) |w| {
            if (w.rule) |rule| {
                if (rule.op != Op.XOR and rule.op != Op.OR) {
                    // print("{s} showing {d} times and gotten with op {any}\n", .{
                    //     kv.key_ptr.*, kv.value_ptr.*, rule.op
                    // });
                    // first value is okay
                    if (!std.mem.eql(u8, rule.input1[1..3], "00") or
                        !std.mem.eql(u8, rule.input1[1..3], "00")) {

                        try wrong.put(kv.key_ptr.*, {});
                    }
                }
            }
        }
    }

    var wrong_arr = ArrayList([]const u8).init(allocator);
    defer wrong_arr.deinit();

    var wrong_it = wrong.keyIterator();
    while (wrong_it.next()) |w| {
        try wrong_arr.append(w.*);
    }

    std.mem.sort([]const u8, wrong_arr.items, {}, comptime stringCompare);

    // skip max z value since it is for carry bit
    for (0.., wrong_arr.items[0..wrong_arr.items.len - 1]) |i, w| {
        if (i == wrong_arr.items.len - 2) {
            print("{s}\n", .{w});
        } else {
            print("{s},", .{w});
        }
    }
}

fn calculateOp(rule: WireRule, wires_map: StringHashMap(Wire)) u1 {
    const val1 = wires_map.get(rule.input1).?.value.?;
    const val2 = wires_map.get(rule.input2).?.value.?;

    switch (rule.op) {
        Op.AND => return val1 & val2,
        Op.OR => return val1 | val2,
        Op.XOR => return val1 ^ val2,
    }

    unreachable;
}

fn calculate(allocator: Allocator, start:[]const u8, wires_map: *StringHashMap(Wire)) !void {
    var stack = ArrayList(*Wire).init(allocator);
    defer stack.deinit();

    try stack.append(wires_map.getPtr(start).?);

    while (stack.items.len != 0) {
        const top = stack.getLast();

        if(top.*.value != null) {
            _ = stack.pop();
            continue;
        }

        var is_ready = true;
        const rule = top.*.rule.?;
        const input1 = rule.input1;
        const input2 = rule.input2;

        if (wires_map.getPtr(input1)) |w1| {
            if (w1.value == null) {
                try stack.append(w1);
                is_ready = false;
            }
        }

        if (wires_map.getPtr(input2)) |w2| {
            if (w2.value == null) {
                try stack.append(w2);
                is_ready = false;
            }
        }

        if (is_ready) {
            top.*.value = calculateOp(rule, wires_map.*);
            _ = stack.pop();
        }
    }
}
