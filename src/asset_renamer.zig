const std = @import("std");
const AssetReference = @import("AssetReference.zig");

pub fn renameReferences(allocator: std.mem.Allocator, references: []AssetReference, new_name: []u8) !void {
    for (references) |reference| {
        try renameReference(allocator, reference, new_name);
    }
}

fn renameReference(allocator: std.mem.Allocator, reference: AssetReference, new_name: []u8) !void {
    var file = try std.fs.openFileAbsolute(
        reference.path,
        .{ .mode = .read_write },
    );
    defer file.close();

    const content = try file.readToEndAlloc(allocator, 10 * 1024 * 1024);
    defer allocator.free(content);

    const replaced_content = try std.mem.replaceOwned(
        u8,
        allocator,
        content,
        reference.asset_name,
        new_name,
    );
    defer allocator.free(replaced_content);

    try file.seekTo(0);
    try file.writeAll(replaced_content);
    try file.setEndPos(replaced_content.len);

    std.debug.print("Replaced references in: {s}\n", .{reference.path});
}
