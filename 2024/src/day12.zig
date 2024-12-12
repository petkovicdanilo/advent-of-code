const std = @import("std");
const print = std.debug.print;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const AutoHashMap = std.AutoHashMap;

const Direction = enum(usize) {
    UP = 0,
    RIGHT,
    DOWN,
    LEFT
};

const dr = [_]i32{ -1, 0, 1,  0 };
const dc = [_]i32{  0, 1, 0, -1 };

const Input = ArrayList(ArrayList(u8));

const Region = struct {
    area: u32,
    perimeter: u32,
};

const Location = struct {
    r: usize,
    c: usize,
};

fn getInput(allocator: Allocator, file_name: []const u8) !Input {
    const file = try std.fs.cwd().openFile(file_name, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;

    var input = ArrayList(ArrayList(u8)).init(allocator);

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line_buf| {
        var row = ArrayList(u8).init(allocator);
        for (0..line_buf.len) |i| {
            try row.append(line_buf[i]);
        }
        try input.append(row);
    }

    return input;
}

fn matrixDeinit(comptime t: type, input: *ArrayList(ArrayList(t))) void {
    for (input.items) |row| {
        row.deinit();
    }
    input.deinit();
}

pub fn solvePartOne() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var input = try getInput(allocator, "examples/day12.txt");
    defer matrixDeinit(u8, &input);

    var visited = ArrayList(ArrayList(bool)).init(allocator);
    defer matrixDeinit(bool, &visited);

    const rows = input.items.len;
    const cols = input.items[0].items.len;

    for (0..rows) |_| {
        var row = ArrayList(bool).init(allocator);
        for (0..cols) |_| {
            try row.append(false);
        }
        try visited.append(row);
    }

    var res: u32 = 0;

    for (0.., input.items) |r, row| {
        for (0.., row.items) |c, _| {
            if (visited.items[r].items[c]) {
                continue;
            }

            visited.items[r].items[c] = true;
            const region = findRegion(r, c, input, &visited);
            res += (region.area * region.perimeter);
        }
    }

    print("{d}\n", .{res});
}

fn inBounds(r: i32, c: i32, rows: usize, cols: usize) bool {
    const rows_i32 = @as(i32, @intCast(rows));
    const cols_i32 = @as(i32, @intCast(cols));

    return (r >= 0 and r < rows_i32 and c >= 0 and c < cols_i32);
}

fn findRegion(
    r: usize,
    c: usize,
    input: Input,
    visited: *ArrayList(ArrayList(bool))) Region {

    var area: u32 = 1;
    var perimeter: u32 = 0;

    const rows = input.items.len;
    const cols = input.items[0].items.len;

    for (0..4) |dir| {
        const neighbour_r_i32 = @as(i32, @intCast(r)) + dr[dir];
        const neighbour_c_i32 = @as(i32, @intCast(c)) + dc[dir];

        if (!inBounds(neighbour_r_i32, neighbour_c_i32, rows, cols)) {
            perimeter += 1;
            continue;
        }

        const neighbour_r = @as(usize, @intCast(neighbour_r_i32));
        const neighbour_c = @as(usize, @intCast(neighbour_c_i32));

        if (input.items[neighbour_r].items[neighbour_c] != input.items[r].items[c]) {
            perimeter += 1;
            continue;
        }

        if (visited.items[neighbour_r].items[neighbour_c]) {
            continue;
        }

        visited.items[neighbour_r].items[neighbour_c] = true;
        const sub_region = findRegion(neighbour_r, neighbour_c, input, visited);
        area += sub_region.area;
        perimeter += sub_region.perimeter;
    }

    return .{
        .area = area,
        .perimeter = perimeter,
    };
}

pub fn solvePartTwo() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var input = try getInput(allocator, "examples/day12.txt");
    defer matrixDeinit(u8, &input);

    var visited = ArrayList(ArrayList(bool)).init(allocator);
    defer matrixDeinit(bool, &visited);

    const rows = input.items.len;
    const cols = input.items[0].items.len;

    for (0..rows) |_| {
        var row = ArrayList(bool).init(allocator);
        for (0..cols) |_| {
            try row.append(false);
        }
        try visited.append(row);
    }

    var res: u32 = 0;

    for (0.., input.items) |r, row| {
        for (0.., row.items) |c, _| {
            if (visited.items[r].items[c]) {
                continue;
            }

            visited.items[r].items[c] = true;
            const locations = try findAllFromRegion(allocator, r, c, input, &visited);
            const area: u32 = @intCast(locations.items.len);
            const edges = try findAllEdges(allocator, locations, input);
            res += (edges * area);
            locations.deinit();
        }
    }

    print("{d}\n", .{res});
}

fn findAllFromRegion(
    allocator: Allocator,
    r: usize,
    c: usize,
    input: Input,
    visited: *ArrayList(ArrayList(bool))) !ArrayList(Location) {

    var stack = ArrayList(Location).init(allocator);
    var locations = ArrayList(Location).init(allocator);

    const rows = input.items.len;
    const cols = input.items[0].items.len;

    try stack.append(.{ .r = r, .c = c});

    while (stack.items.len != 0) {
        const top = stack.pop();
        try locations.append(.{ .r = top.r, .c = top.c});

        for (0..4) |dir| {
            const neighbour_r_i32 = @as(i32, @intCast(top.r)) + dr[dir];
            const neighbour_c_i32 = @as(i32, @intCast(top.c)) + dc[dir];

            if (!inBounds(neighbour_r_i32, neighbour_c_i32, rows, cols)) {
                continue;
            }

            const neighbour_r = @as(usize, @intCast(neighbour_r_i32));
            const neighbour_c = @as(usize, @intCast(neighbour_c_i32));

            if (input.items[neighbour_r].items[neighbour_c] != input.items[r].items[c]) {
                continue;
            }

            if (!visited.items[neighbour_r].items[neighbour_c]) {
                visited.items[neighbour_r].items[neighbour_c] = true;
                try stack.append(.{ .r = neighbour_r, .c = neighbour_c});
            }

        }
    }

    return locations;
}

fn findAllEdges(allocator: Allocator, locations: ArrayList(Location), input: Input) !u32 {
    var visited = AutoHashMap(Location, [4]bool).init(allocator);
    defer visited.deinit();

    for (locations.items) |location| {
        try visited.put(location, .{false, false, false, false});
    }

    var edges: u32 = 0;

    for (0..4) |direction| {
        const d: Direction = @enumFromInt(direction);

        for (locations.items) |location| {
            if (visited.get(location).?[direction]) {
                continue;
            }

            var loc_visited = visited.get(location).?;
            loc_visited[direction] = true;
            try visited.put(location, loc_visited);

            if (!isEdge(location, d, input)) {
                continue;
            }

            try visitEdge(location, d, input, &visited);
            edges += 1;
        }
    }

    return edges;
}

fn isEdge(location: Location, direction: Direction, input: Input) bool {
    const dir: usize = @intFromEnum(direction);

    const neighbour_r_i32 = @as(i32, @intCast(location.r)) + dr[dir];
    const neighbour_c_i32 = @as(i32, @intCast(location.c)) + dc[dir];

    const rows = input.items.len;
    const cols = input.items[0].items.len;

    if (!inBounds(neighbour_r_i32, neighbour_c_i32, rows, cols)) {
        return true;
    }

    const neighbour_r = @as(usize, @intCast(neighbour_r_i32));
    const neighbour_c = @as(usize, @intCast(neighbour_c_i32));

    if (input.items[neighbour_r].items[neighbour_c] !=
        input.items[location.r].items[location.c]) {
        return true;
    }

    return false;
}

fn visitEdge(
    start_location: Location,
    edge_direction: Direction,
    input: Input,
    visited: *AutoHashMap(Location, [4]bool)) !void {

    const rows = input.items.len;
    const cols = input.items[0].items.len;

    const edge_dir: usize = @intFromEnum(edge_direction);

    var search_directions: [2]Direction = undefined;
    if (edge_direction == Direction.UP or edge_direction == Direction.DOWN) {
        search_directions = .{Direction.LEFT, Direction.RIGHT};
    } else {
        search_directions = .{Direction.UP, Direction.DOWN};
    }

    for (search_directions) |search_direction| {
        var location = start_location;
        const search_dir: usize = @intFromEnum(search_direction);

        while (true) {
            const neighbour_r_i32 = @as(i32, @intCast(location.r)) + dr[search_dir];
            const neighbour_c_i32 = @as(i32, @intCast(location.c)) + dc[search_dir];

            if (!inBounds(neighbour_r_i32, neighbour_c_i32, rows, cols)) {
                break;
            }

            const neighbour_location = Location {
                .r = @as(usize, @intCast(neighbour_r_i32)),
                .c = @as(usize, @intCast(neighbour_c_i32)),
            };

            if (input.items[neighbour_location.r].items[neighbour_location.c] !=
                input.items[start_location.r].items[start_location.c]) {
                break;
            }

            if (visited.get(neighbour_location).?[edge_dir]) {
                break;
            }

            var loc_visited = visited.get(neighbour_location).?;
            loc_visited[edge_dir] = true;
            try visited.put(neighbour_location, loc_visited);

            if (!isEdge(neighbour_location, edge_direction, input)) {
                break;
            }

            location = neighbour_location;
        }
    }
}
