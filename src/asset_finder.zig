const std = @import("std");
const Allocator = std.mem.Allocator;
const fs = std.fs;
const AssetReference = @import("AssetReference.zig");
const AssetReferenceOccurence = @import("AssetReferenceOccurence.zig");
const Position = @import("Position.zig");

pub fn findReferences(allocator: Allocator, name: []const u8, proj_dir: fs.Dir) ![]AssetReference {
    var walker = try proj_dir.walk(allocator);
    defer walker.deinit();

    var references = std.ArrayList(AssetReference).init(allocator);

    while (try walker.next()) |entry| {
        // Entry must be a file with proper extension (goto checkExtension)
        if (entry.kind != .file or !checkExtension(entry.path)) continue;

        const asset_reference = try checkAssetRefs(
            allocator,
            name,
            entry,
            proj_dir,
        );

        if (asset_reference) |ref| {
            try references.append(ref);
        }
    }

    return references.toOwnedSlice();
}

fn checkExtension(path: []const u8) bool {
    const extensions = [_][]const u8{
        ".swift",
        ".xib",
        ".plist",
    };

    for (extensions) |extension| {
        if (std.mem.endsWith(u8, path, extension)) return true;
    }

    return false;
}

fn checkAssetRefs(allocator: Allocator, asset_name: []const u8, entry: fs.Dir.Walker.Entry, proj_dir: std.fs.Dir) !?AssetReference {
    const file_abs_path = try proj_dir.realpathAlloc(allocator, entry.path);
    defer allocator.free(file_abs_path);

    var file = try fs.openFileAbsolute(file_abs_path, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    const reader = buf_reader.reader();

    var occurences = std.ArrayList(AssetReferenceOccurence).init(allocator);

    var line_idx: u32 = 0;
    var buf: [10240]u8 = undefined;

    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        defer line_idx += 1;

        const start_pos = std.mem.indexOf(u8, line, asset_name) orelse continue;

        const occurence = try AssetReferenceOccurence.init(
            allocator,
            line_idx,
            .{
                .start = start_pos,
                .end = start_pos + asset_name.len,
            },
            line,
        );

        try occurences.append(occurence);
    }

    if (occurences.items.len > 0) {
        return try AssetReference.init(
            allocator,
            file_abs_path,
            asset_name,
            try occurences.toOwnedSlice(),
        );
    } else {
        occurences.deinit();
        return null;
    }
}
