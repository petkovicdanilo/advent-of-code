const std = @import("std");
const print = std.debug.print;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

pub fn solvePartOne() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const matrix = try getInput(allocator, "inputs/day4.txt");
    var count: u32 = 0;

    const dr = [_]i32{ -1, -1, -1,  0, 0,  1, 1, 1};
    const dc = [_]i32{ -1,  0,  1, -1, 1, -1, 0, 1};

    for (0.., matrix.items) |r, row| {
        for (0.., row.items) |c, val| {
            if (val != 'X') {
                continue;
            }

            for(0..8) |i| {
                if (find("XMAS", matrix, r, c, dr[i], dc[i])) {
                    count += 1;
                }
            }
        }
    }

    print("{d}\n", .{count});

    for (matrix.items) |row| {
        row.deinit();
    }
    matrix.deinit();
}

pub fn solvePartTwo() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const matrix = try getInput(allocator, "inputs/day4.txt");
    var count: u32 = 0;

    const dr = [_]i32{ -1, -1,  1, 1 };
    const dc = [_]i32{ -1,  1, -1, 1 };

    const rows = @as(i32, @intCast(matrix.items.len));
    const cols = @as(i32, @intCast(matrix.items[0].items.len));

    for (0.., matrix.items) |r, row| {
        for (0.., row.items) |c, val| {
            if (val != 'A') {
                continue;
            }

            var mas_count: u32 = 0;
            for(0..4) |i| {
                const start_r = @as(i32, @intCast(r)) + dr[i];
                const start_c = @as(i32, @intCast(c)) + dc[i];

                if (!inBounds(start_r, start_c, rows, cols)) {
                    continue;
                }

                const start_rr = @as(usize, @intCast(start_r));
                const start_cc = @as(usize, @intCast(start_c));
                if (find("MAS", matrix, start_rr, start_cc, -dr[i], -dc[i])) {
                    mas_count += 1;
                }
            }

            if (mas_count == 2) {
                count += 1;
            }
        }
    }

    print("{d}\n", .{count});

    for (matrix.items) |row| {
        row.deinit();
    }
    matrix.deinit();

}

fn inBounds(r: i32, c: i32, rows: i32, cols: i32) bool {
    return (r >= 0 and r < rows and c >= 0 and c < cols);
}

fn find(needle: []const u8, haystack: ArrayList(ArrayList(u8)), r: usize, c: usize, dr: i32, dc: i32) bool {
    if (needle[0] != haystack.items[r].items[c]) {
        return false;
    }

    const rows = @as(i32, @intCast(haystack.items.len));
    const cols = @as(i32, @intCast(haystack.items[0].items.len));
    
    var rr = r;
    var cc = c;

    for (1..needle.len) |i| {
        const ri = @as(i32, @intCast(rr)) + dr;
        const ci = @as(i32, @intCast(cc)) + dc;

        if (!inBounds(ri, ci, rows, cols) ) {
            return false;
        }

        // print("ri = {d}, ci = {d}\n", .{ri, ci});
        rr = @as(usize, @intCast(ri));
        cc = @as(usize, @intCast(ci));
        if (needle[i] != haystack.items[rr].items[cc]) {
            return false;
        }
    }

    return true;
}

fn getInput(allocator: Allocator, file_name: []const u8) !ArrayList(ArrayList(u8)) {
    const file = try std.fs.cwd().openFile(file_name, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;

    var input = ArrayList(ArrayList(u8)).init(allocator);

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line_buf| {
        var line = ArrayList(u8).init(allocator);
        try line.insertSlice(0, line_buf);
        try input.append(line);
    }

    return input;
}
