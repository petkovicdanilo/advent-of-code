const std = @import("std");
const print = std.debug.print;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const AutoHashMap = std.AutoHashMap;

const Equation = struct {
    result: u64,
    numbers: ArrayList(u64),
};
const Input = ArrayList(Equation);

pub fn getInput(allocator: Allocator, file_name: []const u8) !Input {
    const file = try std.fs.cwd().openFile(file_name, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;

    var equations = ArrayList(Equation).init(allocator);

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line_buf| {
        var it = std.mem.split(u8, line_buf, ": ");

        const result_str = it.next().?;
        const result = try std.fmt.parseInt(u64, result_str, 10);

        var numbers = ArrayList(u64).init(allocator);

        const rest = it.next().?;
        var rest_it = std.mem.split(u8, rest, " ");
        while (rest_it.next()) |num_str| {
            const num = try std.fmt.parseInt(u64, num_str, 10);
            try numbers.append(num);
        }
        
        try equations.append(.{
            .result = result,
            .numbers = numbers,
        });
    }

    return equations;
}

pub fn solvePartOne() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var equations = try getInput(allocator, "examples/day7.txt");

    var res: u64 = 0;

    for (equations.items) |equation| {
        // print("{d}: {any}\n", .{equation.result, equation.numbers.items});
        if (try isEquationSolvable(allocator, equation)) {
            res += equation.result;
        }
    }
    
    print("{d}\n", .{res});

    for (equations.items) |equation| {
        equation.numbers.deinit();
    }
    equations.deinit();

}

pub fn solvePartTwo() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var equations = try getInput(allocator, "examples/day7.txt");

    var res: u64 = 0;

    for (equations.items) |equation| {
        // print("{d}: {any}\n", .{equation.result, equation.numbers.items});
        if (try isEquationSolvablePartTwo(allocator, equation)) {
            res += equation.result;
        }
    }
    
    print("{d}\n", .{res});

    for (equations.items) |equation| {
        equation.numbers.deinit();
    }
    equations.deinit();

}

fn isEquationSolvable(allocator: Allocator, equation: Equation) !bool {
    var results = AutoHashMap(u64, void).init(allocator);
    
    try results.put(equation.numbers.items[0], {});
    for (1..equation.numbers.items.len) |i| {
        const curr_number = equation.numbers.items[i];
        var new_results = AutoHashMap(u64, void).init(allocator);

        var results_it = results.keyIterator();
        while (results_it.next()) |res| {
            const res_unwrapped = res.*;
            if (res_unwrapped + curr_number <= equation.result) {
                try new_results.put(res_unwrapped + curr_number, {});
            }

            if (res_unwrapped * curr_number <= equation.result) {
                try new_results.put(res_unwrapped * curr_number, {});
            }
        }

        results.deinit();
        results = new_results;
    }
    defer results.deinit();

    if (results.contains(equation.result)) {
        return true;
    }
    return false;
}

fn isEquationSolvablePartTwo(allocator: Allocator, equation: Equation) !bool {
    var results = AutoHashMap(u64, void).init(allocator);
    
    try results.put(equation.numbers.items[0], {});
    for (1..equation.numbers.items.len) |i| {
        const curr_number = equation.numbers.items[i];
        var new_results = AutoHashMap(u64, void).init(allocator);

        var results_it = results.keyIterator();
        while (results_it.next()) |res| {
            const res_unwrapped = res.*;
            if (res_unwrapped + curr_number <= equation.result) {
                try new_results.put(res_unwrapped + curr_number, {});
            }

            if (res_unwrapped * curr_number <= equation.result) {
                try new_results.put(res_unwrapped * curr_number, {});
            }

            const concatenated = concatenate(res_unwrapped, curr_number);
            if (concatenated <= equation.result) {
                try new_results.put(concatenated, {});
            }
        }

        results.deinit();
        results = new_results;
    }
    defer results.deinit();

    if (results.contains(equation.result)) {
        return true;
    }
    return false;
}

fn concatenate(num1: u64, num2: u64) u64 {
    var num2_digits: u8 = 1;
    var tmp_num2 = num2;
    while (@divTrunc(tmp_num2, 10) > 0) {
        tmp_num2 = @divTrunc(tmp_num2, 10);
        num2_digits += 1;
    }

    return num1 * std.math.pow(u64, 10, num2_digits) + num2;
}
