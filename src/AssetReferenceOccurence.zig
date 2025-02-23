const Self = @This();

const Position = @import("Position.zig");
const std = @import("std");

line: u32,
position: Position,
line_content: []u8,
allocator: std.mem.Allocator,

pub fn init(
    allocator: std.mem.Allocator,
    line: u32,
    position: Position,
    line_content: []u8,
) !Self {
    return Self{
        .line = line,
        .position = position,
        .line_content = try allocator.dupe(u8, line_content),
        .allocator = allocator,
    };
}

pub fn deinit(self: *const Self) void {
    self.*.allocator.free(self.*.line_content);
}
