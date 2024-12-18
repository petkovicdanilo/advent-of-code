const std = @import("std");
const print = std.debug.print;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const Computer = struct {
    A: u64,
    B: u64,
    C: u64,
    program: ArrayList(u3),
    ip: usize,

    const Self = @This();

    pub fn init(allocator: Allocator, file_name: []const u8) !Self {
        const file = try std.fs.cwd().openFile(file_name, .{});
        defer file.close();

        var buf_reader = std.io.bufferedReader(file.reader());
        var in_stream = buf_reader.reader();
        var buf: [1024]u8 = undefined;

        var A: u64 = undefined;
        var B: u64 = undefined;
        var C: u64 = undefined;
        var program = ArrayList(u3).init(allocator);

        var parse_registers = true;

        while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line_buf| {
            if (std.mem.eql(u8, line_buf, "")) {
                parse_registers = false;
                continue;
            }

            const register = line_buf[9];

            if (parse_registers) {
                if (register == 'A') {
                    const A_str = line_buf[12..];
                    A = try std.fmt.parseInt(u64, A_str, 10);
                } else if (register == 'B') {
                    const B_str = line_buf[12..];
                    B = try std.fmt.parseInt(u64, B_str, 10);
                } else if (register == 'C') {
                    const C_str = line_buf[12..];
                    C = try std.fmt.parseInt(u64, C_str, 10);
                }
            } else {
                const program_seq = line_buf[9..];

                var it = std.mem.split(u8, program_seq, ",");
                while (it.next()) |num_str| {
                    const num = try std.fmt.parseInt(u3, num_str, 10);
                    try program.append(num);
                }
            }
        }

        return .{
            .A = A,
            .B = B,
            .C = C,
            .program = program,
            .ip = 0,
        };
    }

    pub fn combo(self: Self, idx: usize) u64 {
        const val = self.program.items[idx];
        switch (val) {
            0...3 => {
                return val;
            },
            4 => {
                return self.A;
            },
            5 => {
                return self.B;
            },
            6 => {
                return self.C;
            },
            7 => {
                unreachable;
            },
        }
    }

    pub fn execute(self: *Self) ?u3 {
        switch (self.program.items[self.ip]) {
            0 => {
                return self.adv();
            },
            1 => {
                return self.bxl();
            },
            2 => {
                return self.bst();
            },
            3 => {
                return self.jnz();
            },
            4 => {
                return self.bxc();
            },
            5 => {
                return self.out();
            },
            6 => {
                return self.bdv();
            },
            7 => {
                return self.cdv();
            },
        }
    }

    pub fn adv(self: *Self) ?u3 {
        const numerator = self.A;

        const operand = self.combo(self.ip + 1);
        const denominator = std.math.pow(u64, 2, operand);
        const result = @divTrunc(numerator, denominator);
        self.A = result;

        self.ip += 2;
        return null;
    }

    pub fn bxl(self: *Self) ?u3 {
        const operand = self.program.items[self.ip + 1];
        self.B ^= operand;

        self.ip += 2;
        return null;
    }

    pub fn bst(self: *Self) ?u3 {
        const operand = self.combo(self.ip + 1);
        self.B = operand % 8;

        self.ip += 2;
        return null;
    }

    pub fn jnz(self: *Self) ?u3 {
        if (self.A == 0) {
            self.ip += 2;
            return null;
        }

        const operand = self.program.items[self.ip + 1];

        self.ip = operand;
        return null;
    }

    pub fn bxc(self: *Self) ?u3 {
        self.B = self.B ^ self.C;
        self.ip += 2;
        return null;
    }

    pub fn out(self: *Self) ?u3 {
        const operand = self.combo(self.ip + 1);
        self.ip += 2;
        return @as(u3, @intCast(operand % 8));
    }

    pub fn bdv(self: *Self) ?u3 {
        const numerator = self.A;

        const operand = self.combo(self.ip + 1);
        const denominator = std.math.pow(u64, 2, operand);
        const result = @divTrunc(numerator, denominator);
        self.B = result;

        self.ip += 2;
        return null;
    }

    pub fn cdv(self: *Self) ?u3 {
        const numerator = self.A;

        const operand = self.combo(self.ip + 1);
        const denominator = std.math.pow(u64, 2, operand);
        const result = @divTrunc(numerator, denominator);
        self.C = result;

        self.ip += 2;
        return null;
    }

    pub fn deinit(self: *Self) void {
        self.*.program.deinit();
    }
};


pub fn solvePartOne() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var computer = try Computer.init(allocator, "examples/day17.txt");
    defer computer.deinit();

    var res = ArrayList(u3).init(allocator);
    defer res.deinit();

    while (computer.ip < computer.program.items.len) {
       if (computer.execute()) |val| {
            try res.append(val);
       }
    }

    for (0.., res.items) |i, val| {
        print("{d}", .{val});
        if (i != res.items.len - 1) {
            print(",", .{});
        }
    }
    print("\n", .{});
}

pub fn solvePartTwo() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var computer = try Computer.init(allocator, "examples/day17.txt");
    defer computer.deinit();

    var skip: u6 = 0;
    for (0.., computer.program.items) |i, op| {
        if (i % 2 != 0) {
            continue;
        }
        
        // if we shift A register before we use it, we can ignore these bits;
        if (op == 0) {
            skip += 3;
        } else if (op == 2 and computer.program.items[i + 1] == 4) {
            break;
        } else if (op == 5 and computer.program.items[i + 1] == 4) {
            break;
        } else if (op == 6 or op == 7) {
            break;
        }
    }

    var A: u64 = 0;
    const program_len = computer.program.items.len;

    A = find(&computer, program_len - 1, A, skip).?;
    print("{d}\n", .{A});
}

fn find(computer: *Computer, idx: usize, A: u64, skip: u6) ?u64 {
    for (0..8) |a| {
        computer.A = ((A >> skip) << 3 | a) << skip;
        computer.B = 0;
        computer.C = 0;
        computer.ip = 0;
        
        var output: u3 = undefined;

        while(true) {
            if(computer.execute()) |val| {
                output = val;
                break;
            }
        }
        
        if (output != computer.program.items[idx]) {
            continue;
        }
 
        const new_A = ((A >> skip) << 3 | a) << skip;
        if (idx == 0) {
            return new_A;
        }
        if (find(computer, idx - 1, new_A, skip)) |val| {
            return val;
        }
    }

    return null;
}
