const std = @import("std");
const Asset = @import("Asset.zig");

pub fn parseCatalog(allocator: std.mem.Allocator, asset_catalog: std.fs.Dir) ![]Asset {
    return try collectAssetImages(allocator, asset_catalog);
}

fn collectAssetImages(allocator: std.mem.Allocator, asset_catalog: std.fs.Dir) ![]Asset {
    var walker = try asset_catalog.walk(allocator);
    defer walker.deinit();

    var assets = std.ArrayList(Asset).init(allocator);

    while (try walker.next()) |entry| {
        const imageset_idx = std.mem.indexOf(u8, entry.basename, ".imageset");
        // Image set is directory with .imageset extension
        if (entry.kind != .directory or imageset_idx == null) continue;

        const asset = try makeAsset(allocator, asset_catalog, &entry);
        try assets.append(asset);
    }
    return assets.toOwnedSlice();
}

fn makeAsset(
    allocator: std.mem.Allocator,
    asset_catalog: std.fs.Dir,
    entry: *const std.fs.Dir.Walker.Entry,
) !Asset {
    const image_set_path = try asset_catalog.realpathAlloc(allocator, entry.path);

    const contents_file_path = try std.fmt.allocPrint(
        allocator,
        "{s}/Contents.json",
        .{image_set_path},
    );

    var name: []u8 = undefined;

    if (std.mem.indexOf(u8, entry.basename, ".imageset")) |extension_idx|
        name = try allocator.dupe(u8, entry.basename[0..extension_idx])
    else
        name = try allocator.dupe(u8, entry.basename);

    return Asset{
        .image_set_path = image_set_path,
        .contents_file_path = contents_file_path,
        .name = name,
    };
}
