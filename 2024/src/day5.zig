const std = @import("std");
const print = std.debug.print;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const AutoHashMap = std.AutoHashMap;

const RulesMap = AutoHashMap(u32, AutoHashMap(u32, void));
const Update = ArrayList(u32);
const Updates = ArrayList(Update);

const Input = struct {
    allocator: Allocator,
    rules_map: RulesMap,
    updates: Updates,

    const Self = @This();

    pub fn init(allocator: Allocator, file_name: []const u8) !Self {
        const file = try std.fs.cwd().openFile(file_name, .{});
        defer file.close();

        var buf_reader = std.io.bufferedReader(file.reader());
        var in_stream = buf_reader.reader();
        var buf: [1024]u8 = undefined;

        var rules_map = RulesMap.init(allocator);
        var updates = Updates.init(allocator);

        var first_section = true;
        while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line_buf| {
            if (std.mem.eql(u8, line_buf, "")) {
                first_section = false;
                continue;
            }

            if (first_section) {
                var it = std.mem.split(u8, line_buf, "|");
                const first_str = it.next() orelse unreachable;
                const first = try std.fmt.parseInt(u32, first_str, 10);

                const second_str = it.next() orelse unreachable;
                const second = try std.fmt.parseInt(u32, second_str, 10);

                var rules = rules_map.get(first);
                if (rules) |*r| {
                    // print("putting {d} in {d}, count = {d}\n", .{second, first, r.count()});
                    try r.*.put(second, {});
                } else {
                    var r = AutoHashMap(u32, void).init(allocator);
                    try r.ensureTotalCapacity(50); // not sure why this was map was not auto growing
                    // print("creating and putting {d} in {d}\n", .{second, first});
                    try r.put(second, {});
                    try rules_map.put(first, r);
                }
            } else {
                var it = std.mem.split(u8, line_buf, ",");

                var update = Update.init(allocator);
                while (it.next()) |val_str| {
                    const val = try std.fmt.parseInt(u32, val_str, 10);
                    try update.append(val);
                }

                try updates.append(update);
            }
        }

        return .{
            .allocator = allocator,
            .rules_map = rules_map,
            .updates = updates,
        };
    }
    
    pub fn deinit(self: *Self) void {
        for (self.*.updates.items) |update| {
            update.deinit();
        }
        self.*.updates.deinit();

        var it = self.*.rules_map.iterator();
        while (it.next()) |r| {
            r.value_ptr.*.deinit();
        }
        self.*.rules_map.deinit();
    }
};

pub fn solvePartOne() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var input = try Input.init(allocator, "examples/day5.txt");
    defer input.deinit();

    // var it = input.rules_map.iterator();
    // while (it.next()) |entry| {
    //     print("{d}: (", .{entry.key_ptr.*});
    //     var inner_it = entry.value_ptr.*.keyIterator();
    //     while (inner_it.next()) |val| {
    //         print(" {d}", .{val.*});
    //     }
    //     print(" )\n", .{});
    // }

    var res: u32 = 0;

    for (input.updates.items) |update| {
        if (!try checkUpdate(allocator, update.items, input.rules_map)) {
            const mid = middle(update.items);
            // print("update {any} is good, adding {d}\n", .{update.items, mid});
            res += mid;
        }
    }
    print("{d}\n", .{res});
}

pub fn solvePartTwo() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var input = try Input.init(allocator, "inputs/day5.txt");
    defer input.deinit();

    // var it = input.rules_map.iterator();
    // while (it.next()) |entry| {
    //     print("{d}: (", .{entry.key_ptr.*});
    //     var inner_it = entry.value_ptr.*.keyIterator();
    //     while (inner_it.next()) |val| {
    //         print(" {d}", .{val.*});
    //     }
    //     print(" )\n", .{});
    // }

    var res: u32 = 0;

    for (input.updates.items) |*update| {
        const valid = try checkUpdate(allocator, update.items, input.rules_map);
        if (!valid) {
            try topologicalSort(allocator, &update.items, input.rules_map);
            const mid = middle(update.items);
            res += mid;
        }
    }
    print("{d}\n", .{res});
}

fn checkUpdate(allocator: Allocator, update: []u32, rules_map: RulesMap) !bool {
    var visited = AutoHashMap(u32, void).init(allocator);
    defer visited.deinit();

    for (update) |val| {
        // var visited_it = visited.keyIterator();
        // while (visited_it.next()) |v| {
        //     print("{d} ", .{v.*});
        // }
        // print("\n", .{});

        const rules = rules_map.get(val) orelse {
            try visited.put(val, {});
            continue;
        };

        var it = rules.keyIterator();
        while (it.next()) |val_after| {
            if (visited.contains(val_after.*)) {
                // print("update {any} is NOT good, conflict at {d} because {d} is visited\n", .{update, val, val_after.*});
                return false;
            }
        }
        try visited.put(val, {});
    }

    return true;
}

fn middle(update: []u32) u32 {
    if (update.len == 1) {
        return update[0];
    }

    const mid: usize = @divExact(update.len - 1, 2);
    return update[mid];
}

fn topologicalSort(allocator: Allocator, update: *[]u32, rules_map: RulesMap) !void {
    var elements = AutoHashMap(u32, bool).init(allocator);
    defer elements.deinit();
    for (update.*) |el| {
        try elements.put(el, false);
    }

    // print(" (", .{});
    // var it = elements.keyIterator();
    // while (it.next()) |key| {
    //     print(" {d}", .{key.*});
    // }
    // print(" )\n", .{});

    var order_stack = ArrayList(u32).init(allocator);

    for (update.*) |el| {
        if (!elements.get(el).?) {
            try elements.put(el, true);
            try dfs(el, &elements, rules_map, &order_stack);
        }
    }

    const l = update.*.len;
    for(0..l) |i| {
        update.*[i] = order_stack.pop();
    }
}

fn dfs(el: u32, elements: *AutoHashMap(u32, bool), rules_map: RulesMap, order_stack: *ArrayList(u32)) !void {
    const rules = rules_map.get(el) orelse {
        try order_stack.*.append(el);
        return;
    };

    var it = rules.keyIterator();
    while (it.next()) |val_after| {
        if (elements.contains(val_after.*) and !elements.get(val_after.*).?) {
            try elements.put(val_after.*, true);
            try dfs(val_after.*, elements, rules_map, order_stack);
        }
    }
    
    try order_stack.*.append(el);
}
