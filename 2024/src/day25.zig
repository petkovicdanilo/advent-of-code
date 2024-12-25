const std = @import("std");
const print = std.debug.print;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const ROWS = 7;
const COLS = 5;

const Input = struct {
    allocator: Allocator,
    keys: ArrayList([COLS]u8),
    locks: ArrayList([COLS]u8),

    const Self = @This();

    fn init(allocator: Allocator, file_name: []const u8) !Self {
        const file = try std.fs.cwd().openFile(file_name, .{});
        defer file.close();

        var buf_reader = std.io.bufferedReader(file.reader());
        var in_stream = buf_reader.reader();
        var buf: [1024]u8 = undefined;

        var locks = ArrayList([COLS]u8).init(allocator);
        var keys = ArrayList([COLS]u8).init(allocator);

        var inputs = ArrayList([ROWS][COLS]u8).init(allocator);
        defer inputs.deinit();

        var curr: [ROWS][COLS]u8 = undefined;
        var curr_row: usize = 0;

        while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line_buf| {
            if (std.mem.eql(u8, line_buf, "")) {
                curr_row = 0;
                try inputs.append(curr);
                continue;
            }

            for (0.., line_buf) |c, ch| {
                curr[curr_row][c] = ch;
            }

            curr_row += 1;
        }
        try inputs.append(curr);

        for (inputs.items) |map| {
            var pin_heights: [COLS]u8 = undefined;

            if (isLock(map)) {
                for (0..COLS) |c| {
                    pin_heights[c] = 0;
                }

                for (1..ROWS) |r| {
                    for (0..COLS) |c| {
                        if(map[r][c] == '#') {
                            pin_heights[c] += 1;
                        }
                    }
                }

                try locks.append(pin_heights);
            } else {
                for (0..COLS) |c| {
                    pin_heights[c] = 0;
                }

                for (0..ROWS - 1) |r| {
                    for (0..COLS) |c| {
                        if(map[r][c] == '#') {
                            pin_heights[c] += 1;
                        }
                    }
                }

                try keys.append(pin_heights);
            }
        }

        return .{
            .allocator = allocator,
            .keys = keys,
            .locks = locks,
        };
    }

    fn deinit(self: *Self) void {
        self.*.keys.deinit();
        self.*.locks.deinit();
    }
};

fn isLock(map: [ROWS][COLS]u8) bool {
    for (0..COLS) |c| {
        if (map[0][c] == '.') {
            return false;
        }
    }

    return true;
}

pub fn solvePartOne() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var input = try Input.init(allocator, "examples/day25.txt");
    defer input.deinit();

    // for (input.keys.items) |k| {
    //     print("{d} ", .{k});
    // }
    // print("\n", .{});
    //
    // for (input.locks.items) |l| {
    //     print("{d} ", .{l});
    // }
    // print("\n", .{});

    var res: u32 = 0;
    
    for (input.locks.items) |lock| {
        for (input.keys.items) |key| {
            var ok = true;

            for (0..COLS) |c| {
                if (lock[c] + key[c] >= ROWS - 1) {
                    ok = false;
                    break;
                }
            }

            if (ok) {
                res += 1;
            }
        }
    }

    print("{d}\n", .{res});
}
