const std = @import("std");
const print = std.debug.print;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const AutoHashMap = std.AutoHashMap;
const StringHashMap = std.StringHashMap;

const dr = [_]i32{  0, 1, 0, -1 };
const dc = [_]i32{ -1, 0, 1,  0 };

const Direction = enum(usize) {
    LEFT = 0,
    DOWN,
    RIGHT,
    UP,
};

const Location = struct {
    r: usize,
    c: usize,
};

const Keyboard = struct {
    key_to_location_map: AutoHashMap(u8, Location),
    location_to_key_map: AutoHashMap(Location, u8),

    fn newNumPad(allocator: Allocator) !Keyboard {
        var key_to_location_map = AutoHashMap(u8, Location).init(allocator);

        try key_to_location_map.put('7', .{.r = 0, .c = 0});
        try key_to_location_map.put('8', .{.r = 0, .c = 1});
        try key_to_location_map.put('9', .{.r = 0, .c = 2});

        try key_to_location_map.put('4', .{.r = 1, .c = 0});
        try key_to_location_map.put('5', .{.r = 1, .c = 1});
        try key_to_location_map.put('6', .{.r = 1, .c = 2});

        try key_to_location_map.put('1', .{.r = 2, .c = 0});
        try key_to_location_map.put('2', .{.r = 2, .c = 1});
        try key_to_location_map.put('3', .{.r = 2, .c = 2});

        try key_to_location_map.put('0', .{.r = 3, .c = 1});
        try key_to_location_map.put('A', .{.r = 3, .c = 2});

        var location_to_key_map = AutoHashMap(Location, u8).init(allocator);

        var it = key_to_location_map.iterator();
        while (it.next()) |kv| {
            try location_to_key_map.put(kv.value_ptr.*, kv.key_ptr.*);
        }

        return .{
            .key_to_location_map = key_to_location_map,
            .location_to_key_map = location_to_key_map,
        };
    }

    fn newDPad(allocator: Allocator) !Keyboard {
        var key_to_location_map = AutoHashMap(u8, Location).init(allocator);
        try key_to_location_map.put('^', .{.r = 0, .c = 1});
        try key_to_location_map.put('A', .{.r = 0, .c = 2});

        try key_to_location_map.put('<', .{.r = 1, .c = 0});
        try key_to_location_map.put('v', .{.r = 1, .c = 1});
        try key_to_location_map.put('>', .{.r = 1, .c = 2});

        var location_to_key_map = AutoHashMap(Location, u8).init(allocator);

        var it = key_to_location_map.iterator();
        while (it.next()) |kv| {
            try location_to_key_map.put(kv.value_ptr.*, kv.key_ptr.*);
        }

        return .{
            .key_to_location_map = key_to_location_map,
            .location_to_key_map = location_to_key_map,
        };
    }

    fn getKeyAt(self: Keyboard, location: Location) ?u8 {
        return self.location_to_key_map.get(location);
    }

    fn getLocation(self: Keyboard, key: u8) ?Location {
        return self.key_to_location_map.get(key);
    }

    fn deinit(self: *Keyboard) void {
        self.*.location_to_key_map.deinit();
        self.*.key_to_location_map.deinit();
    }
};

const Input = ArrayList([]u8);

fn getInput(allocator: Allocator, file_name: []const u8) !Input {
    const file = try std.fs.cwd().openFile(file_name, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;

    var input = Input.init(allocator);

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line_buf| {
        const in = try allocator.alloc(u8, line_buf.len);
        @memcpy(in, line_buf);
        try input.append(in);
    }

    return input;
}

const SequenceMap = std.StringHashMap(AutoHashMap(u8, u64));

pub fn solvePartOne() !void {
    try solve(2, "examples/day21.txt");
}

pub fn solvePartTwo() !void {
    try solve(25, "examples/day21.txt");
}

fn solve(levels: u8, file_name: []const u8) !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var input = try getInput(allocator, file_name);
    defer input.deinit();

    var num_pad = try Keyboard.newNumPad(allocator);
    defer num_pad.deinit();

    var d_pad = try Keyboard.newDPad(allocator);
    defer d_pad.deinit();

    var memo = SequenceMap.init(allocator);

    var res: u64 = 0;

    for (input.items) |number| {
        var curr: u8 = 'A';
        var curr_location = num_pad.getLocation(curr).?;

        var acc_res: u64 = 0;

        for (0..number.len) |next_idx| {
            const next = number[next_idx];
            const next_location = num_pad.getLocation(next).?;

            var paths = try getAllPossiblePaths(
                allocator,
                curr_location,
                next_location,
                num_pad
            );
            defer paths.deinit();

            var it = paths.keyIterator();
            var curr_res: u64 = std.math.maxInt(u64);
            while (it.next()) |path| {
                curr_res = @min(
                    curr_res,
                    try solveInput(allocator, 'A', path.*, levels, d_pad, &memo)
                );
            }

            curr = next;
            curr_location = next_location;
            acc_res += curr_res;
        }

        const numericPart = try std.fmt.parseInt(u32, number[0..number.len - 1], 10);
        res += numericPart * acc_res;
    }

    print("{d}\n", .{res});

    for (input.items) |in| {
        allocator.free(in);
    }

    var it = memo.valueIterator();
    while (it.next()) |v| {
        v.*.deinit();
    }
    memo.deinit();
}

fn getDirChar(d: Direction) u8 {
    switch (d) {
        Direction.UP => {
            return '^';
        },
        Direction.RIGHT => {
            return '>';
        },
        Direction.DOWN => {
            return 'v';
        },
        Direction.LEFT => {
            return '<';
        },
    }

    unreachable;
}

fn getButtonDist(l1: Location, l2: Location, d: Direction) usize {
    switch (d) {
        Direction.UP => {
            if (l1.r <= l2.r) {
                return 0;
            }
            return l1.r - l2.r;
        },
        Direction.RIGHT => {
            if (l2.c <= l1.c) {
                return 0;
            }
            return l2.c - l1.c;
        },
        Direction.DOWN => {
            if (l2.r <= l1.r) {
                return 0;
            }
            return l2.r - l1.r;
        },
        Direction.LEFT => {
            if (l1.c <= l2.c) {
                return 0;
            }
            return l1.c - l2.c;
        },
    }

    unreachable;
}

fn getDirectionMovements(allocator: Allocator, l1: Location, l2: Location) ![]usize {
    var res = try allocator.alloc(usize, 4);

    for (0..4) |dir| {
        const direction: Direction = @enumFromInt(dir);
        const d = getButtonDist(l1, l2, direction);
        res[dir] = d;
    }

    return res;
}


fn getAllPossiblePaths(
    allocator: Allocator,
    l1: Location,
    l2: Location,
    keyboard: Keyboard,
) Allocator.Error!StringHashMap(void) {
    var ret = StringHashMap(void).init(allocator);

    var paths = try getAllPossiblePathsInner(allocator, l1, l2, keyboard);
    defer paths.deinit();

    var it = paths.keyIterator();
    while (it.next()) |path| {
        var new_path = ArrayList(u8).init(allocator);
        for (path.*) |el| {
            try new_path.append(el);
        }
        try new_path.append('A');
        try ret.put(new_path.items, {});
    }

    return ret;
}

fn getAllPossiblePathsInner(
    allocator: Allocator,
    l1: Location,
    l2: Location,
    keyboard: Keyboard,
) Allocator.Error!StringHashMap(void) {

    var ret = StringHashMap(void).init(allocator);

    if (l1.r == l2.r and l1.c == l2.c) {
        try ret.put("", {});
        return ret;
    }

    const movements = try getDirectionMovements(allocator, l1, l2);
    defer allocator.free(movements);

    for (0..4) |dir| {
        const direction: Direction = @enumFromInt(dir);

        var movement = movements[dir];
        if (movement == 0) {
            continue;
        }

        const next_r_i32 = @as(i32, @intCast(l1.r)) + dr[dir];
        const next_c_i32 = @as(i32, @intCast(l1.c)) + dc[dir];

        const next_r: usize = @intCast(next_r_i32);
        const next_c: usize = @intCast(next_c_i32);

        if (keyboard.getKeyAt(.{.r = next_r, .c = next_c}) == null) {
            continue;
        }

        movement -= 1;
        var sub_paths = try getAllPossiblePathsInner(
            allocator, .{ .r = next_r, .c = next_c }, l2, keyboard
        );
        defer sub_paths.deinit();

        var it = sub_paths.keyIterator();
        while (it.next()) |sub_path| {
            var new_path = ArrayList(u8).init(allocator);

            const ch = getDirChar(direction);
            try new_path.append(ch);

            for (sub_path.*) |c| {
                try new_path.append(c);
            }

            try ret.put(new_path.items, {});
        }

        movement += 1;
    }

    return ret;
}

fn nextDir(dir: usize) usize {
    if (dir == 3) {
        return 0;
    }

    return dir + 1;
}


fn solveInput(
    allocator: Allocator, 
    start: u8,
    input: []const u8,
    steps: u8,
    keyboard: Keyboard,
    memo: *SequenceMap
) Allocator.Error!u64 {

    if (steps == 0) {
        return input.len;
    }

    if (memo.get(input)) |val| {
        if (val.get(steps)) |inner| {
            return inner;
        }
    }

    var res: u64 = 0;

    var curr = start;

    for (0..input.len) |i| {
        const next = input[i];
        res += try solvePair(allocator, curr, next, steps, keyboard, memo);
        curr = next;
    }

    if (memo.getPtr(input)) |val| {
        try val.*.put(steps, res);
    } else {
        var inner_map = AutoHashMap(u8, u64).init(allocator);
        try inner_map.put(steps, res);
        try memo.put(input, inner_map);
    }

    return res;
}

fn solvePair(
    allocator: Allocator,
    start: u8,
    end: u8,
    steps: u8,
    keyboard: Keyboard,
    memo: *SequenceMap
) Allocator.Error!u64 {

    const start_location = keyboard.getLocation(start).?;
    const end_location = keyboard.getLocation(end).?;

    var possible_paths = try getAllPossiblePaths(
        allocator,
        start_location,
        end_location,
        keyboard
    );
    defer possible_paths.deinit();

    var curr_res: u64 = std.math.maxInt(u64);

    var it = possible_paths.keyIterator();
    while (it.next()) |path| {
        curr_res = @min(
            curr_res,
            try solveInput(allocator, 'A', path.*, steps - 1, keyboard, memo)
        );
    }

    return curr_res;
}
