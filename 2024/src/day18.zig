const std = @import("std");
const print = std.debug.print;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const PriorityQueue = std.PriorityQueue;

const Position = struct {
    r: usize,
    c: usize,
};

const Input = ArrayList(Position);

const PositionDist = struct {
    r: usize,
    c: usize,
    dist: u32,
};

const dr = [_]i32{ -1, 0, 1,  0 };
const dc = [_]i32{  0, 1, 0, -1 };

fn getInput(allocator: Allocator, file_name: []const u8) !Input {
    const file = try std.fs.cwd().openFile(file_name, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;

    var input = Input.init(allocator);

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line_buf| {
        var it = std.mem.split(u8, line_buf, ",");
        const c_str = it.next().?;
        const r_str = it.next().?;

        const c = try std.fmt.parseInt(usize, c_str, 10);
        const r = try std.fmt.parseInt(usize, r_str, 10);

        try input.append(.{.r = r, .c = c});
    }

    return input;
}

// for example
const R = 7;
const C = 7;

// for input
// const R = 71;
// const C = 71;

pub fn solvePartOne() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var input = try getInput(allocator, "examples/day18.txt");
    defer input.deinit();

    var map: [R][C]u8 = undefined;

    for (0..R) |r| {
        for (0..C) |c| {
            map[r][c] = '.';
        }
    }

    // for input
    const LIMIT = 1024;

    // for example
    // const LIMIT = 12;

    for (0.., input.items) |i, falling| {
        if (i == LIMIT) {
            break;
        }
        map[falling.r][falling.c] = '#';
    }

    const start_r = 0;
    const start_c = 0;

    const end_r = R - 1;
    const end_c = C - 1;

    const dist_map = try dijkstra(allocator, start_r, start_c, map);

    print("{d}\n", .{dist_map[end_r][end_c]});
}

fn positonDistLessThan(_: void, a: PositionDist, b: PositionDist) std.math.Order {
    return std.math.order(a.dist, b.dist);
}

fn inBounds(r: i32, c: i32,) bool {
    const rows_i32 = @as(i32, @intCast(R));
    const cols_i32 = @as(i32, @intCast(C));

    return (r >= 0 and r < rows_i32 and c >= 0 and c < cols_i32);
}

fn dijkstra(
    allocator: Allocator,
    start_r: usize,
    start_c: usize,
    map: [R][C]u8) ![R][C]u32 {

    var dist: [R][C]u32 = undefined;

    for (0..R) |r| {
        for (0..C) |c| {
            dist[r][c] = std.math.maxInt(u32);
        }
    }

    dist[start_r][start_c] = 0;

    var pq = PriorityQueue(PositionDist, void, positonDistLessThan).init(allocator, {});
    defer pq.deinit();

    try pq.add(.{
        .r = start_r,
        .c = start_c,
        .dist = 0
    });

    while (pq.items.len != 0) {
        const curr = pq.remove();

        for (0..4) |d| {
            const next_r_i32 = @as(i32, @intCast(curr.r)) + dr[d];
            const next_c_i32 = @as(i32, @intCast(curr.c)) + dc[d];

            if (!inBounds(next_r_i32, next_c_i32)) {
                continue;
            }

            const next_r: usize = @intCast(next_r_i32);
            const next_c: usize = @intCast(next_c_i32);

            if (map[next_r][next_c] == '#') {
                continue;
            }

            var next_dist = dist[next_r][next_c];
            const curr_dist = dist[curr.r][curr.c];

            if (next_dist > curr_dist + 1) {
                next_dist = curr_dist + 1;
                dist[next_r][next_c] = next_dist;
                try pq.add(.{
                    .r = next_r,
                    .c = next_c,
                    .dist = next_dist,
                });
            }
        }
    }

    return dist;
}

pub fn solvePartTwo() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var input = try getInput(allocator, "examples/day18.txt");
    defer input.deinit();

    var map: [R][C]u8 = undefined;

    for (0..R) |r| {
        for (0..C) |c| {
            map[r][c] = '.';
        }
    }

    const start_r = 0;
    const start_c = 0;

    const end_r = R - 1;
    const end_c = C - 1;

    var res: Position = undefined;

    var l: usize = 0;
    var r: usize = input.items.len - 1;
    while (l <= r) {
        const mid = @divTrunc(l + r, 2);
        for (l..mid + 1) |i| {
            const falling = input.items[i];
            map[falling.r][falling.c] = '#';
        }

        const dist_map = try dijkstra(allocator, start_r, start_c, map);

        if (dist_map[end_r][end_c] == std.math.maxInt(u32)) {
            res = input.items[mid];

            for (l..mid + 1) |i| {
                const falling = input.items[i];
                map[falling.r][falling.c] = '.';
            }

            r = mid - 1;
        } else {
            l = mid + 1;
        }
    }

    print("{d},{d}\n", .{res.c, res.r});
}
