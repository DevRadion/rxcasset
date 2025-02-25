const Self = @This();

const std = @import("std");
const AssetReferenceOccurence = @import("AssetReferenceOccurence.zig");

path: []u8,
asset_name: []const u8,
occurences: []AssetReferenceOccurence,
allocator: std.mem.Allocator,

pub fn init(allocator: std.mem.Allocator, path: []u8, asset_name: []const u8, occurences: []AssetReferenceOccurence) !Self {
    return Self{
        .path = try allocator.dupe(u8, path),
        .asset_name = try allocator.dupe(u8, asset_name),
        .occurences = occurences,
        .allocator = allocator,
    };
}

pub fn deinit(self: *const Self) void {
    for (self.occurences) |occur| {
        occur.deinit();
    }

    self.allocator.free(self.path);
    self.allocator.free(self.asset_name);
    self.allocator.free(self.occurences);
}
