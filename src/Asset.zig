const Self = @This();

const std = @import("std");

image_set_path: []u8,
contents_file_path: []u8,
name: []u8,

pub fn deinit(self: Self, allocator: std.mem.Allocator) void {
    allocator.free(self.image_set_path);
    allocator.free(self.contents_file_path);
    allocator.free(self.name);
}
