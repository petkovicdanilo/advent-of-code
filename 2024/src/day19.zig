const std = @import("std");
const print = std.debug.print;
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const Allocator = std.mem.Allocator;
const StringHashMap = std.StringHashMap;

const Input = struct {
    allocator: Allocator,
    designs: ArrayList([]const u8),
    patterns: ArrayList([]const u8),

    const Self = @This();

    fn init(allocator: Allocator, file_name: []const u8) !Self {
        const file = try std.fs.cwd().openFile(file_name, .{});
        defer file.close();

        var buf_reader = std.io.bufferedReader(file.reader());
        var in_stream = buf_reader.reader();
        var buf: [1024 * 1024]u8 = undefined;

        var patterns = ArrayList([]const u8).init(allocator);
        var designs = ArrayList([]const u8).init(allocator);

        var parse_patterns = true;

        while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line_buf| {
            if (std.mem.eql(u8, line_buf, "")) {
                parse_patterns = false;
                continue;
            }

            if (parse_patterns) {
                var it = std.mem.split(u8, line_buf, ", ");
                while (it.next()) |val| {
                    const d = try allocator.alloc(u8, val.len);
                    @memcpy(d, val);
                    try patterns.append(d);
                }
            } else {
                const p = try allocator.alloc(u8, line_buf.len);
                @memcpy(p, line_buf);
                try designs.append(p);
            }
        }

        return .{
            .allocator = allocator,
            .patterns = patterns,
            .designs = designs,
        };
    }

    fn deinit(self: *Self) void {
        for (self.*.designs.items) |d| {
            self.*.allocator.free(d);
        }
        self.*.designs.deinit();

        for (self.*.patterns.items) |p| {
            self.*.allocator.free(p);
        }
        self.*.patterns.deinit();
    }
};

pub fn solvePartOne() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var input = try Input.init(allocator, "examples/day19.txt");
    defer input.deinit();

    var len_to_patterns = AutoHashMap(usize, StringHashMap(void)).init(allocator);
    for (input.patterns.items) |pattern| {
        const l = pattern.len;
        if (len_to_patterns.getPtr(l)) |l_patterns| {
            try l_patterns.*.put(pattern, {});
        } else {
            var l_patterns = StringHashMap(void).init(allocator);
            try l_patterns.put(pattern, {});
            try len_to_patterns.put(l, l_patterns);
        }
    }

    // var it = len_to_patterns.iterator();
    // while (it.next()) |kv| {
    //     print("{d}: ", .{kv.key_ptr.*});
    //     var inner_it = kv.value_ptr.keyIterator();
    //     while (inner_it.next()) |k| {
    //         print("{s} ", .{k.*});
    //     }
    //     print("\n", .{});
    // }

    var res: u32 = 0;

    for (input.designs.items) |design| {
        var memo = try ArrayList(?bool).initCapacity(allocator, design.len + 1);
        defer memo.deinit();

        for (0..design.len + 1) |i| {
            if (i == design.len) {
                try memo.append(true);
            } else {
                try memo.append(null);
            }
        }

        if (possible(0, design, len_to_patterns, &memo)) {
            res += 1;
        }
    }

    print("{d}\n", .{res});
}

fn possible(
    idx: usize,
    design: []const u8,
    len_to_patterns: AutoHashMap(usize, StringHashMap(void)),
    memo: *ArrayList(?bool)
) bool {

    if (memo.items[idx]) |val| {
        return val;
    }

    if (design.len == 0) {
        memo.items[idx] = true;
        return true;
    }

    var it = len_to_patterns.iterator();
    while (it.next()) |kv| {
        const l = kv.key_ptr.*;
        const l_patterns = kv.value_ptr.*;
        if (design.len < l) {
            continue;
        }

        if (l_patterns.get(design[0..l])) |_| {
            if (possible(idx + l, design[l..], len_to_patterns, memo)) {
                memo.items[idx] = true;
                return true;
            }
        }
    }

    memo.items[idx] = false;
    return false;
}

pub fn solvePartTwo() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var input = try Input.init(allocator, "examples/day19.txt");
    defer input.deinit();

    var len_to_patterns = AutoHashMap(usize, StringHashMap(void)).init(allocator);
    for (input.patterns.items) |pattern| {
        const l = pattern.len;
        if (len_to_patterns.getPtr(l)) |l_patterns| {
            try l_patterns.*.put(pattern, {});
        } else {
            var l_patterns = StringHashMap(void).init(allocator);
            try l_patterns.put(pattern, {});
            try len_to_patterns.put(l, l_patterns);
        }
    }

    // var it = len_to_patterns.iterator();
    // while (it.next()) |kv| {
    //     print("{d}: ", .{kv.key_ptr.*});
    //     var inner_it = kv.value_ptr.keyIterator();
    //     while (inner_it.next()) |k| {
    //         print("{s} ", .{k.*});
    //     }
    //     print("\n", .{});
    // }

    var res: u64 = 0;

    for (input.designs.items) |design| {
        var memo = try ArrayList(?u64).initCapacity(allocator, design.len + 1);
        defer memo.deinit();

        for (0..design.len + 1) |i| {
            if (i == design.len) {
                try memo.append(1);
            } else {
                try memo.append(null);
            }
        }

        res += possible2(0, design, len_to_patterns, &memo);
    }

    print("{d}\n", .{res});
}

fn possible2(
    idx: usize,
    design: []const u8,
    len_to_patterns: AutoHashMap(usize, StringHashMap(void)),
    memo: *ArrayList(?u64)
) u64 {

    if (memo.items[idx]) |val| {
        return val;
    }

    if (design.len == 0) {
        memo.items[idx] = 1;
        return 1;
    }
    
    var res: u64 = 0;

    var it = len_to_patterns.iterator();
    while (it.next()) |kv| {
        const l = kv.key_ptr.*;
        const l_patterns = kv.value_ptr.*;
        if (design.len < l) {
            continue;
        }

        if (l_patterns.get(design[0..l])) |_| {
            res += possible2(idx + l, design[l..], len_to_patterns, memo);
        }
    }

    memo.items[idx] = res;
    return res;
}
