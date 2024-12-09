const std = @import("std");
const print = std.debug.print;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const AutoHashMap = std.AutoHashMap;

const Section = struct {
    len: usize,
    file_id: ?u32,
    start_idx: usize, // needed only for part two
};

const Input = ArrayList(Section);

fn getInput(allocator: Allocator, file_name: []const u8) !Input {
    const file = try std.fs.cwd().openFile(file_name, .{});
    defer file.close();

    var parse_file = true;
    var input = Input.init(allocator);
    var curr_file_id: u32 = 0;
    var curr_idx: usize = 0;

    const file_buffer = try file.readToEndAlloc(allocator, 1024*1024);
    defer allocator.free(file_buffer);

    for (0..file_buffer.len - 1) |i| {
        const num = try std.fmt.parseInt(usize, file_buffer[i..i+1], 10);
        if (parse_file) {
            try input.append(.{
                .len = num,
                .file_id = curr_file_id,
                .start_idx = curr_idx,
            });

            curr_file_id += 1;
        } else {
            try input.append(.{
                .len = num,
                .file_id = null,
                .start_idx = curr_idx,
            });
        }
        curr_idx += num;
        parse_file = !parse_file;
    }
    
    return input;
}

pub fn solvePartOne() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const input = try getInput(allocator, "examples/day9.txt");
    var curr_block: usize = 0;
    var checksum: u64 = 0;

    var left: usize = 0;
    var right: usize = input.items.len - 1;

    if (input.items[right].file_id == null) {
        right -= 1;
    }

    while (left <= right) {
        if (left % 2 == 0) {
            for (0..input.items[left].len) |_| {
                // print("adding {d} * {d}\n", .{input.items[left].file_id.?, curr_block});
                checksum += input.items[left].file_id.? * curr_block;
                curr_block += 1;
            }
            left += 1;
            continue;
        }

        const left_len = input.items[left].len;
        const right_len = input.items[right].len;

        const min_len = @min(left_len, right_len);
        for (0..min_len) |_| {
            // print("adding {d} * {d}\n", .{input.items[right].file_id.?, curr_block});
            checksum += input.items[right].file_id.? * curr_block;
            curr_block += 1;
        }
        input.items[left].len -= min_len;
        input.items[right].len -= min_len;

        if (left_len == min_len) {
            left += 1;
        }

        if (right_len == min_len) {
            right -= 2;
        }
    }

    print("{d}\n", .{checksum});
}

pub fn solvePartTwo() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const input = try getInput(allocator, "examples/day9.txt");
    var checksum: u64 = 0;

    var right: usize = input.items.len - 1;
    if (input.items[right].file_id == null) {
        right -= 1;
    }

    while (right > 0) {
        var left: usize = 1;

        // find gap where input.items[right] would fit.
        while (left < right) {
            const left_len = input.items[left].len;
            if (left_len > 0 and left_len >= input.items[right].len) {
                break;
            }
            left += 2;
        }

        if (left >= right) {
            // didn't find any gap that would fit file input.items[right]
            right -= 2;
            continue;
        }

        input.items[right].start_idx = input.items[left].start_idx;

        input.items[left].len -= input.items[right].len;
        input.items[left].start_idx += input.items[right].len;
        
        right -= 2;
    }

    for (0.., input.items) |i, el| {
        if (i % 2 != 0) {
            continue;
        }

        for (0..el.len) |idx| {
            checksum += (el.start_idx + idx) * el.file_id.?;
        }
    }

    print("{d}\n", .{checksum});
}
