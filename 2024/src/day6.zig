const std = @import("std");
const print = std.debug.print;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const Tuple = std.meta.Tuple;

const dr = [_]i32{ -1, 0, 1,  0 };
const dc = [_]i32{  0, 1, 0, -1 };

const Direction = enum(usize) {
    UP = 0,
    RIGHT,
    DOWN,
    LEFT
};

const Player = struct {
    r: usize,
    c: usize,
    direction: Direction,
};

const Input = struct {
    allocator: Allocator,
    grid: ArrayList(ArrayList(u8)),
    player: Player,

    const Self = @This();

    pub fn init(allocator: Allocator, file_name: []const u8) !Self {
        const file = try std.fs.cwd().openFile(file_name, .{});
        defer file.close();

        var buf_reader = std.io.bufferedReader(file.reader());
        var in_stream = buf_reader.reader();
        var buf: [1024]u8 = undefined;

        var grid = ArrayList(ArrayList(u8)).init(allocator);
        var player_r: usize = 0;
        var player_c: usize = 0;
        const player_direction: Direction = Direction.UP;

        while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line_buf| {
            var row = ArrayList(u8).init(allocator);
            for (0.., line_buf) |c, char| {
                if (char == '.' or char == '#') {
                    try row.append(char);
                } else if (char == '^') {
                    player_r = grid.items.len;
                    player_c = c;
                    try row.append('.');
                }
            }
            try grid.append(row);
        }

        return .{
            .allocator = allocator,
            .grid = grid,
            .player = .{
                .r = player_r,
                .c = player_c,
                .direction = player_direction,
            }
        };
    }
    
    pub fn deinit(self: *Self) void {
        for (self.*.grid.items) |row| {
            row.deinit();
        }
        self.*.grid.deinit();
    }
};

pub fn solvePartOne() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var input = try Input.init(allocator, "inputs/day6.txt");
    defer input.deinit();

    var player = input.player;
    const grid = input.grid;

    // for each i,j in which directions have we visited i,j
    var visited = ArrayList(ArrayList([4]bool)).init(allocator);
    for (grid.items) |_| {
        var row = ArrayList([4]bool).init(allocator);
        row.clone();
        for (grid.items[0].items) |_| {
            try row.append(.{ false, false, false, false });
        }
        try visited.append(row);
    }

    for (visited.items) |visited_row| {
        defer visited_row.deinit();
    }
    defer visited.deinit();

    // print("Marking start position at {d} {d} in direction {} as visited\n", .{player.r, player.c, player.direction});
    visited.items[player.r].items[player.c][@intFromEnum(player.direction)] = true;
    var num_visited: u32 = 1;

    while (true) {
        // print("Player at {d} {d} in direction {}\n", .{player.r, player.c, player.direction});
        const d = @intFromEnum(player.direction);
        const new_rr = @as(i32, @intCast(player.r)) + dr[d];
        const new_cc = @as(i32, @intCast(player.c)) + dc[d];
        // print("New position at {d} {d}\n", .{new_rr, new_cc});
        if (!inBounds(new_rr, new_cc, grid)) {
            // print("New position not in bounds, exiting\n", .{});
            break;
        }

        const new_r = @as(usize, @intCast(new_rr));
        const new_c = @as(usize, @intCast(new_cc));
        if (grid.items[new_r].items[new_c] == '.') {
            // print(". is at new position\n", .{});
            if (visited.items[new_r].items[new_c][d]) {
                // print("We already visited {d} {d} in direction {}. Exiting\n", .{new_rr, new_cc, player.direction});
                break;
            }
            // print("We haven't visited {d} {d} in direction {}\n", .{new_rr, new_cc, player.direction});

            var cell_visited = false;
            for (visited.items[new_r].items[new_c]) |visited_dir| {
                if (visited_dir) {
                    cell_visited = true;
                    break;
                }
            }

            if (!cell_visited) {
                // print("We haven't visited {d} {d}. Adding it.\n", .{new_rr, new_cc});
                num_visited += 1;
            }

            visited.items[new_r].items[new_c][d] = true;

            player.r = new_r;
            player.c = new_c;
        } else {
            player.direction = nextDirection(player.direction);
            // print("Hit the barrier, changing direction to {}\n", .{player.direction});
        }
    }
    
    print("{d}\n", .{num_visited});
}

pub fn solvePartTwo() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var input = try Input.init(allocator, "examples/day6.txt");
    defer input.deinit();

    var player = input.player;
    const grid = input.grid;

    // for each i,j in which directions have we visited i,j
    var visited = ArrayList(ArrayList([4]bool)).init(allocator);
    const rows = grid.items.len;
    const cols = grid.items[0].items.len;
    for (0..rows) |_| {
        var row = ArrayList([4]bool).init(allocator);
        for (0..cols) |_| {
            try row.append(.{ false, false, false, false });
        }
        try visited.append(row);
    }


    const start_r = player.r;
    const start_c = player.c;

    visited.items[start_r].items[start_c][@intFromEnum(player.direction)] = true;
    var num_barriers: u32 = 0;

    while (true) {
        const d = @intFromEnum(player.direction);
        const new_rr = @as(i32, @intCast(player.r)) + dr[d];
        const new_cc = @as(i32, @intCast(player.c)) + dc[d];
        if (!inBounds(new_rr, new_cc, grid)) {
            break;
        }

        const new_r = @as(usize, @intCast(new_rr));
        const new_c = @as(usize, @intCast(new_cc));
        if (grid.items[new_r].items[new_c] == '.') {
            if (visited.items[new_r].items[new_c][d]) {
                break;
            }

            var cell_visited = false;
            for (visited.items[new_r].items[new_c]) |visited_dir| {
                if (visited_dir) {
                    cell_visited = true;
                    break;
                }
            }

            if (!cell_visited and (new_r != start_r or new_c != start_c)) {
                // check if grid has cycle starting from the same position
                // changing direction and modfying (new_r, new_c) to be #
                grid.items[new_r].items[new_c] = '#';

                const new_direction = nextDirection(player.direction);
                const has_cycle = try hasCycle(
                    allocator,
                    player.r,
                    player.c,
                    new_direction,
                    grid,
                    &visited
                );

                if (has_cycle) {
                    num_barriers += 1;
                }

                grid.items[new_r].items[new_c] = '.';
            }

            visited.items[new_r].items[new_c][d] = true;

            player.r = new_r;
            player.c = new_c;
        } else {
            player.direction = nextDirection(player.direction);
        }
    }

    for (visited.items) |visited_row| {
        defer visited_row.deinit();
    }
    defer visited.deinit();
    
    print("{d}\n", .{num_barriers});
}

fn inBounds(r: i32, c: i32, grid: ArrayList(ArrayList(u8))) bool {
    return (r >= 0 and r < grid.items.len and c >= 0 and c < grid.items[0].items.len);
}

fn nextDirection(direction: Direction) Direction {
    var new_direction = @intFromEnum(direction) + 1;
    if (new_direction == 4) {
        new_direction = 0;
    }

    return @enumFromInt(new_direction);
}

fn hasCycle(
    allocator: Allocator,
    start_r: usize,
    start_c: usize,
    direction: Direction,
    grid: ArrayList(ArrayList(u8)),
    visited: *ArrayList(ArrayList([4]bool))
) !bool {

    var player = Player {
        .r = start_r,
        .c = start_c,
        .direction = direction,
    };

    var has_cycle = false;
    var visited_list = ArrayList(Tuple(&.{usize, usize, Direction})).init(allocator);
    try visited_list.append(.{start_r, start_c, direction});

    visited.items[player.r].items[player.c][@intFromEnum(player.direction)] = true;

    while (true) {
        const d = @intFromEnum(player.direction);
        const new_rr = @as(i32, @intCast(player.r)) + dr[d];
        const new_cc = @as(i32, @intCast(player.c)) + dc[d];
        if (!inBounds(new_rr, new_cc, grid)) {
            has_cycle = false;
            break;
        }

        const new_r = @as(usize, @intCast(new_rr));
        const new_c = @as(usize, @intCast(new_cc));
        if (grid.items[new_r].items[new_c] == '.') {
            if (visited.items[new_r].items[new_c][d]) {
                has_cycle = true;
                break;
            }

            visited.items[new_r].items[new_c][d] = true;
            try visited_list.append(.{new_r, new_c, @enumFromInt(d)});

            player.r = new_r;
            player.c = new_c;
        } else {
            player.direction = nextDirection(player.direction);
        }
    }

    // undo all changes in visited matrix
    for (visited_list.items) |a| {
        const visited_r = a[0];
        const visited_c = a[1];
        const visited_d = @intFromEnum(a[2]);

        visited.items[visited_r].items[visited_c][visited_d] = false;
    }
    visited_list.deinit();

    return has_cycle;
}
