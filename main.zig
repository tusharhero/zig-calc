// The GPLv3 License (GPLv3)

// Copyright © 2024 tusharhero

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

const std = @import("std");
const stdout = std.io.getStdOut().writer();
const stdin = std.io.getStdIn().reader();
const max_size = 32768;

const Operators = enum(u8) {
    plus = '+',
    minus = '-',
    multiple = '*',
    division = '/',
    fn toChar(self: Operators) u8 {
        return @enumToInt(self);
    }
    fn fromChar(c: u8) ?Operators {
        return switch (c) {
            '+', '-', '*', '/' => @intToEnum(Operators, c),
            else => null,
        };
    }
};
const Token = union(enum) {
    number: u64,
    operator: Operators,
};

const isDigit = std.ascii.isDigit;
fn isOperator(c: u8) bool {
    return std.meta.intToEnum(Operators, c) != error.InvalidEnumTag;
}

fn cleanInput(allocator: std.mem.Allocator, input: []u8) ![]u8 {
    var cleaned_input = std.ArrayList(u8).init(allocator);
    for (input) |c| {
        var is_digit: bool = isDigit(c);
        var is_operator: bool = isOperator(c);
        if (is_digit or is_operator) {
            try cleaned_input.append(c);
        }
    }
    return cleaned_input.toOwnedSlice();
}

fn addNumberString(number_string: *std.ArrayList(u8), tokens: *std.ArrayList(Token)) !void {
    try tokens.append(Token{ .number = try std.fmt.parseInt(
        u64,
        number_string.toOwnedSlice(),
        10,
    ) });
}

fn tokenizer(allocator: std.mem.Allocator, string: []u8) !std.ArrayList(Token) {
    var tokens = std.ArrayList(Token).init(allocator);
    errdefer tokens.deinit();

    var cleaned_string = try cleanInput(allocator, string);

    var number_string = std.ArrayList(u8).init(allocator);
    defer number_string.deinit();

    var in_number = false;

    for (cleaned_string) |c| {
        var is_digit = isDigit(c);
        var is_operator = isOperator(c);

        if (is_digit) {
            in_number = true;
            try number_string.append(c);
        } else if (is_operator) {
            if (in_number) {
                in_number = false;
                try addNumberString(&number_string, &tokens);
            }
            try tokens.append(Token{ .operator = Operators.fromChar(c).? });
        }
    }
    if (in_number) {
        try addNumberString(&number_string, &tokens);
    }
    return tokens;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(!gpa.deinit());
    const allocator = gpa.allocator();

    while (b: {
        try stdout.print("> ", .{});
        break :b try stdin.readUntilDelimiterOrEofAlloc(allocator, '\n', max_size);
    }) |input| : (allocator.free(input)) {
        var tokens = try tokenizer(allocator, input);
        defer tokens.deinit();
        try stdout.print("{any}\n", .{tokens.items});
    }
}
