const std = @import("std");
const print = std.debug.print;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const Tuple = std.meta.Tuple;
const ParseMulResult = Tuple(&.{?u32, []u8});
const ParseCommandResult = Tuple(&.{?bool, []u8});
const ParseIntResult = Tuple(&.{?u32, []u8});
const ExpectResult = Tuple(&.{bool, []u8});

pub fn solvePartOne() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const input = try getInput(allocator, "inputs/day3.txt");
    defer allocator.free(input);
     
    var result: u64 = 0;

    var to_parse = input[0..];
    while (to_parse.len > 0) {
        if (to_parse.len >= 4 and std.mem.eql(u8, to_parse[0..4], "mul(")) {
            const mul_res = parseMul(to_parse);
            if (mul_res[0]) |val| {
                result += val;
            }
            to_parse = mul_res[1];
            continue;
        }
        to_parse = to_parse[1..];
    }
    print("{d}\n", .{result});
}

pub fn solvePartTwo() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const input = try getInput(allocator, "inputs/day3.txt");
    defer allocator.free(input);

    var result: u64 = 0;
    var enabled = true;

    var to_parse = input[0..];

    while (to_parse.len > 0) {
        if (to_parse.len >= 4 and std.mem.eql(u8, to_parse[0..4], "do()")) {
            // print("parsing do() ", .{});
            to_parse = to_parse[4..];
            // print("continuing with {s}\n", .{to_parse});
            enabled = true;
            continue;
        }
        else if (to_parse.len >= 7 and std.mem.eql(u8, to_parse[0..7], "don't()")) {
            // print("parsing don't() ", .{});
            to_parse = to_parse[7..];
            // print("continuing with {s}\n", .{to_parse});
            enabled = false;
            continue;
        }
        else if (to_parse.len >= 4 and std.mem.eql(u8, to_parse[0..4], "mul(")) {
            // print("parsing mul( ", .{});
            const mul_res = parseMul(to_parse);
            if (mul_res[0]) |val| {
                if (enabled) {
                    result += val;
                    // print("enabled so adding {d}, new result {d}\n", .{val, result});
                } else {
                    // print("disabled so skipping {d}\n", .{val});
                }
            }
            to_parse = mul_res[1];
            continue;
        }

        to_parse = to_parse[1..];
    }
    print("{d}\n", .{result});
}

fn expect(input: []u8, c: u8) ExpectResult {
    if (input.len == 0) {
        return .{
            false,
            &.{},
        };
    }

    if (input[0] == c) {
        return .{
            true,
            input[1..],
        };
    }

    return .{
        false,
        input,
    };
}

fn parseMul(input: []u8) ParseMulResult {
    // parse mul(
    var to_parse = input[4..];
    // print("parsed mul( , rest is {s}\n", .{to_parse});

    const val1_res = parseInt(to_parse);
    if (val1_res[0] == null) {
        // print("int not found, continuing from {s}\n", .{val1_res[1]});
        return .{
            null,
            val1_res[1]
        };
    }
    const val1 = val1_res[0] orelse unreachable;
    to_parse = val1_res[1];
    // print("int {d} found, continuing from {s}\n", .{val1, to_parse});

    const comma = expect(to_parse, ',');
    if (!comma[0]) {
        // print(", not found, continuing from {s}\n", .{comma[1]});
        return .{
            null,
            comma[1],
        };
    }
    to_parse = comma[1];
    // print(", found, continuing from {s}\n", .{to_parse});

    const val2_res = parseInt(to_parse);
    if (val2_res[0] == null) {
        return .{
            null,
            val2_res[1]
        };
    }
    const val2 = val2_res[0] orelse unreachable;
    to_parse = val2_res[1];
    // print("int {d} found, continuing from {s}\n", .{val2, to_parse});

    const closing_paren = expect(to_parse, ')');
    if (!closing_paren[0]) {
        // print(") not found, continuing from {s}\n", .{closing_paren[1]});
        return .{
            null,
            closing_paren[1],
        };
    }
    to_parse = closing_paren[1];
    // print(") found, continuing from {s}\n", .{to_parse});


    // print("mul result {d} found, continuing from {s}\n", .{val1 * val2, to_parse});
    return .{
        val1 * val2,
        to_parse,
    };
}

fn isDigit(c: u8) bool {
    return c >= '0' and c <= '9';
}

fn parseInt(input: []u8) ParseIntResult {
    if (input.len == 0) {
        return .{
            null,
            &.{},
        };
    }
    
    if (!isDigit(input[0])) {
        return .{
            null,
            input[0..]
        };
    }

    var curr: usize = 0;
    var num: u32 = 0;
    while (isDigit(input[curr])) {
        const digit = std.fmt.parseInt(u32, input[curr..curr+1], 10) catch unreachable;
        num = (num * 10) + digit;
        curr += 1;
        if (curr == 3) {
            break;
        }
    }

    return .{
        num,
        input[curr..]
    };
}

fn getInput(allocator: Allocator, file_name: []const u8) ![]u8 {
    const file = try std.fs.cwd().openFile(file_name, .{});
    defer file.close();

    const stat = try file.stat();

    return try file.readToEndAlloc(allocator, stat.size);
}
