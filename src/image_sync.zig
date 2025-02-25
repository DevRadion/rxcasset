const std = @import("std");
const Asset = @import("Asset.zig");

const AssetFile = struct {
    filename: []u8,
};

pub fn syncImageSets(allocator: std.mem.Allocator, assets: []Asset) !void {
    for (assets) |asset| {
        const asset_filenames = try getAssetFiles(allocator, asset);
        defer {
            for (asset_filenames) |filename| {
                allocator.free(filename);
            }
            allocator.free(asset_filenames);
        }

        if (checkAssetCoherence(asset, asset_filenames)) continue;
        try syncAsset(allocator, asset, asset_filenames);
    }
}

fn syncAsset(allocator: std.mem.Allocator, asset: Asset, asset_filenames: [][]u8) !void {
    var asset_dir = try std.fs.openDirAbsolute(asset.image_set_path, .{});
    defer asset_dir.close();

    for (asset_filenames) |asset_filename| {
        const new_filename = try renameFilename(
            allocator,
            asset.name,
            asset_filename,
        );
        defer allocator.free(new_filename);

        try renameFilenameInContents(
            allocator,
            asset,
            asset_filename,
            new_filename,
        );
        try asset_dir.rename(asset_filename, new_filename);

        std.debug.print(
            "Replaced filename for: {s}\nOld: {s}\nNew: {s}\n\n",
            .{ asset.image_set_path, asset_filename, new_filename },
        );
    }
}

fn renameFilenameInContents(allocator: std.mem.Allocator, asset: Asset, old_filename: []u8, new_filename: []u8) !void {
    var contents_file = try std.fs.openFileAbsolute(
        asset.contents_file_path,
        .{ .mode = .read_write },
    );
    defer contents_file.close();

    const contents_file_content = try contents_file.readToEndAlloc(allocator, 5120);
    defer allocator.free(contents_file_content);

    const contents_file_content_replaced = try std.mem.replaceOwned(
        u8,
        allocator,
        contents_file_content,
        old_filename,
        new_filename,
    );
    defer allocator.free(contents_file_content_replaced);

    try contents_file.seekTo(0);
    try contents_file.writeAll(contents_file_content_replaced);
    try contents_file.setEndPos(contents_file_content_replaced.len);
}

fn renameFilename(allocator: std.mem.Allocator, basename: []u8, filename: []u8) ![]u8 {
    if (getFilenameExtensionsStart(filename)) |extension_idx| {
        return try std.fmt.allocPrint(
            allocator,
            "{s}{s}",
            .{ basename, filename[extension_idx..] },
        );
    }

    if (getFilenameScaleStart(filename)) |scale_idx| {
        return try std.fmt.allocPrint(
            allocator,
            "{s}{s}",
            .{ basename, filename[0..scale_idx] },
        );
    }

    return filename;
}

fn checkExtension(filename: []const u8) bool {
    const extensions = [_][]const u8{
        ".pdf",
        ".svg",
        ".png",
        ".jpg",
    };

    for (extensions) |extension| {
        if (std.mem.endsWith(u8, filename, extension)) return true;
    }

    return false;
}

fn getImageBasename(filename: []u8) []u8 {
    if (getFilenameScaleStart(filename)) |scale_idx|
        return filename[0..scale_idx];

    if (getFilenameExtensionsStart(filename)) |extension_idx|
        return filename[0..extension_idx];

    return filename;
}

fn getFilenameScaleStart(filename: []u8) ?usize {
    if (std.mem.indexOf(u8, filename, "@")) |scale_idx| {
        return scale_idx;
    }

    return null;
}

fn getFilenameExtensionsStart(filename: []u8) ?usize {
    if (std.mem.lastIndexOf(u8, filename, ".")) |extension_idx| {
        return extension_idx;
    }

    return null;
}

fn getAssetFiles(allocator: std.mem.Allocator, asset: Asset) ![][]u8 {
    var asset_folder = try std.fs.openDirAbsolute(
        asset.image_set_path,
        .{ .iterate = true },
    );
    defer asset_folder.close();

    var file_list = std.ArrayList([]u8).init(allocator);
    var iter = asset_folder.iterate();

    while (try iter.next()) |entry| {
        if (!checkExtension(entry.name)) continue;
        try file_list.append(try allocator.dupe(u8, entry.name));
    }

    return try file_list.toOwnedSlice();
}

fn checkAssetCoherence(asset: Asset, asset_filenames: [][]u8) bool {
    for (asset_filenames) |asset_filename| {
        const basename = getImageBasename(asset_filename);
        if (!std.mem.eql(u8, basename, asset.name)) return false;
    }

    return true;
}
