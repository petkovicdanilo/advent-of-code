const std = @import("std");
const print = std.debug.print;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const Input = struct {
    x1: i64,
    y1: i64,
    x2: i64,
    y2: i64,
    prize_x: i64,
    prize_y: i64,
};

fn getInput(allocator: Allocator, file_name: []const u8) !ArrayList(Input) {
    const file = try std.fs.cwd().openFile(file_name, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;

    var input = ArrayList(Input).init(allocator);

    var parse_stage: usize = 0;
    var x1: i64 = 0;
    var x2: i64 = 0;
    var y1: i64 = 0;
    var y2: i64 = 0;

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line_buf| {
        if (std.mem.eql(u8, line_buf, "")) {
            continue;
        }

        if (parse_stage == 0) {
            const b = line_buf[9..];
            var it = std.mem.split(u8, b, ", ");

            const x1_str = it.next().?[2..];
            const y1_str = it.next().?[2..];
            
            x1 = try std.fmt.parseInt(i64, x1_str, 10);
            y1 = try std.fmt.parseInt(i64, y1_str, 10);

            parse_stage = 1;

        } else if (parse_stage == 1) {
            const b = line_buf[9..];
            var it = std.mem.split(u8, b, ", ");

            const x2_str = it.next().?[2..];
            const y2_str = it.next().?[2..];
            
            x2 = try std.fmt.parseInt(i64, x2_str, 10);
            y2 = try std.fmt.parseInt(i64, y2_str, 10);
            parse_stage = 2;

        } else if (parse_stage == 2) {
            const b = line_buf[7..];
            var it = std.mem.split(u8, b, ", ");

            const prize_x_str = it.next().?[2..];
            const prize_y_str = it.next().?[2..];
            
            const prize_x = try std.fmt.parseInt(i64, prize_x_str, 10);
            const prize_y = try std.fmt.parseInt(i64, prize_y_str, 10);

            try input.append(.{
                .x1 = x1,
                .x2 = x2,
                .y1 = y1,
                .y2 = y2,
                .prize_x = prize_x,
                .prize_y = prize_y,
            });
            parse_stage = 0;
        }
    }

    return input;
}

pub fn solvePartOne() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const input = try getInput(allocator, "examples/day13.txt");
    defer input.deinit();

    var res: u64 = 0;

    for (input.items) |i| {
        res += solve(i);
    }

    print("{d}\n", .{res});
}

pub fn solvePartTwo() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const input = try getInput(allocator, "examples/day13.txt");
    defer input.deinit();

    var res: u64 = 0;

    for (input.items) |*i| {
        i.*.prize_x += 10000000000000;
        i.*.prize_y += 10000000000000;
        res += solve(i.*);
    }

    print("{d}\n", .{res});
}

fn solve(input: Input) u64 {
    const D = (input.x1 * input.y2 - input.y1 * input.x2);
    const Da = (input.prize_x * input.y2 - input.prize_y * input.x2);
    const Db = (input.x1 * input.prize_y - input.y1 * input.prize_x);

    if (D != 0) {
        // exactly one solution

        // non-integer solutions
        if (@rem(Da, D) != 0 or @rem(Db, D) != 0) {
            return 0;
        }

        const a = @divExact(Da, D);
        // negative solution
        if (a <= 0) {
            return 0;
        }

        const b = @divExact(Db, D);
        // negative solution
        if (b <= 0) {
            return 0;
        }

        return @as(u64, @intCast(3*a + b));
    }

    if (Da != 0) {
        // no solutions
        return 0;
    }

    // infinitely many solutions
    if (input.x1 == 3 * input.x2) {
        return @as(
            u64,
            @intCast(@divExact(input.prize_x, input.x2))
        );
    } else if (input.x1 < 3 * input.x2) {
        // minimize first
        var a: i64 = 0;

        while (true) {
            const numerator = input.prize_x - a * input.x1;
            const denominator = input.x2;

            if (@rem(numerator, denominator) != 0) {
                a += 1;
                continue;
            }

            const b = @divExact(numerator, denominator);
            return @as(u64, @intCast(3*a + b));
        }
    } else {
        // minimize second
        var b: i64 = 0;

        while (true) {
            const numerator = input.prize_x - b * input.x2;
            const denominator = input.x1;

            if (@rem(numerator, denominator) != 0) {
                b += 1;
                continue;
            }

            const a = @divExact(numerator, denominator);
            return @as(u64, @intCast(3*a + b));
        }
    }

    return 0;
}
