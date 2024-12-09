const std = @import("std");
const print = std.debug.print;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const AutoHashMap = std.AutoHashMap;
const PriorityQueue = std.PriorityQueue;

const Section = struct {
    len: usize,
    file_id: ?u32,
};

const Input = ArrayList(Section);

fn getInput(allocator: Allocator, file_name: []const u8) !Input {
    const file = try std.fs.cwd().openFile(file_name, .{});
    defer file.close();

    var parse_file = true;
    var input = Input.init(allocator);
    var curr_file_id: u32 = 0;

    const file_buffer = try file.readToEndAlloc(allocator, 1024*1024);
    defer allocator.free(file_buffer);

    for (0..file_buffer.len - 1) |i| {
        const num = try std.fmt.parseInt(usize, file_buffer[i..i+1], 10);
        if (parse_file) {
            try input.append(.{
                .len = num,
                .file_id = curr_file_id,
            });

            curr_file_id += 1;
        } else {
            try input.append(.{
                .len = num,
                .file_id = null,
            });
        }
        parse_file = !parse_file;
    }
    
    return input;
}

const SectionPartTwo = struct {
    len: usize,
    file_id: u32,
    start_idx: usize,
};

fn lessThan(context: void, a: usize, b: usize) std.math.Order {
    _ = context;
    return std.math.order(a, b);
}

const InputPartTwo = struct {
    free_space_map: [10]PriorityQueue(usize, void, lessThan),
    file_sections: ArrayList(SectionPartTwo),
};

fn getInputPartTwo(allocator: Allocator, file_name: []const u8) !InputPartTwo {
    const file = try std.fs.cwd().openFile(file_name, .{});
    defer file.close();

    var parse_file = true;
    var curr_file_id: u32 = 0;
    var curr_idx: usize = 0;

    const file_buffer = try file.readToEndAlloc(allocator, 1024*1024);
    defer allocator.free(file_buffer);

    var free_space_map: [10]PriorityQueue(usize, void, lessThan) = undefined;
    for (0..10) |i| {
        free_space_map[i] = PriorityQueue(usize, void, lessThan).init(allocator, {});
    }
    var file_sections = ArrayList(SectionPartTwo).init(allocator);

    for (0..file_buffer.len - 1) |i| {
        const len = try std.fmt.parseInt(usize, file_buffer[i..i+1], 10);
        if (parse_file) {
            try file_sections.append(.{
                .len = len,
                .file_id = curr_file_id,
                .start_idx = curr_idx,
            });

            curr_file_id += 1;
        } else {
            try free_space_map[len].add(curr_idx);
        }
        curr_idx += len;
        parse_file = !parse_file;
    }
    
    return .{
        .free_space_map = free_space_map,
        .file_sections = file_sections,
    };
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

    var input = try getInputPartTwo(allocator, "examples/day9.txt");
    var checksum: u64 = 0;

    var right: usize = input.file_sections.items.len - 1;

    while (right >= 0) {
        var file = input.file_sections.items[right];

        var min_space_len: usize = 0;
        var free_space_start_idx: usize = std.math.maxInt(usize);

        for (file.len..10) |len| {
            var free_space_queue = input.free_space_map[len];
            if (free_space_queue.peek()) |idx| {
                if (idx < free_space_start_idx) {
                    free_space_start_idx = idx;
                    min_space_len = len;
                }
            }
        }

        if (free_space_start_idx == std.math.maxInt(usize) or free_space_start_idx > file.start_idx) {
            // couldn't find slot for this file
            for (0..file.len) |idx| {
                checksum += (file.start_idx + idx) * file.file_id;
            }
            if (right == 0) {
                break;
            }
            right -= 1;
            continue;
        }

        var free_space_queue = input.free_space_map[min_space_len];
        _ = free_space_queue.remove();
        input.free_space_map[min_space_len] = free_space_queue;

        if (min_space_len - file.len > 0) {
            const new_space_len = min_space_len - file.len;
            const new_free_space_start_idx = free_space_start_idx + file.len;

            var new_free_space_queue = input.free_space_map[new_space_len];
            try new_free_space_queue.add(new_free_space_start_idx);
            input.free_space_map[new_space_len] = new_free_space_queue;
        }

        file.start_idx = free_space_start_idx;
        for (0..file.len) |idx| {
            checksum += (file.start_idx + idx) * file.file_id;
        }
         
        if (right == 0) {
            break;
        }

        right -= 1;
    }

    for (input.free_space_map) |free_space_queue| {
        defer free_space_queue.deinit();
    }

    print("{d}\n", .{checksum});
}
