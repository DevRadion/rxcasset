const std = @import("std");
const chameleon = @import("chameleon");
const finder = @import("asset_finder.zig");
const AssetReference = @import("AssetReference.zig");
const renamer = @import("asset_renamer.zig");
const Arguments = @import("Arguments.zig");
const catalog_parser = @import("catalog_parser.zig");
const image_sync = @import("image_sync.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    const argv = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, argv);

    var arguments = try Arguments.parse(
        allocator,
        argv,
    );
    defer arguments.deinit();

    if (!validateArguments(arguments)) return;

    printArguments(arguments);

    if (arguments.is_asset_sync == true) {
        const path = arguments.xcassets_path orelse return;
        try performAssetSync(allocator, path);
    } else if (arguments.is_reference_replacement == true) {
        const path = arguments.project_path orelse return;
        try performReferenceReplacement(
            allocator,
            path,
            arguments.asset_name.?,
            arguments.asset_new_name,
        );
    }
}

fn performAssetSync(allocator: std.mem.Allocator, xcassets_path: []u8) !void {
    const dir = try std.fs.openDirAbsolute(xcassets_path, .{ .iterate = true });
    const assets = try catalog_parser.parseCatalog(allocator, dir);
    defer {
        for (assets) |asset| {
            asset.deinit(allocator);
        }
        allocator.free(assets);
    }

    try image_sync.syncImageSets(allocator, assets);
}

fn performReferenceReplacement(allocator: std.mem.Allocator, project_path: []u8, old: []u8, new: ?[]u8) !void {
    var c = chameleon.initRuntime(.{ .allocator = allocator });
    defer c.deinit();

    const proj_dir = try std.fs.openDirAbsolute(
        project_path,
        .{ .iterate = true },
    );

    const references = try finder.findReferences(
        allocator,
        old,
        proj_dir,
    );
    defer {
        for (references) |reference| {
            reference.deinit();
        }
        allocator.free(references);
    }

    for (references) |reference| {
        try printAssetReference(&c, reference);
    }

    const asset_new_name = new orelse {
        std.debug.print("For replacement - add -new param with new asset name\n", .{});
        return;
    };

    if (getUserAgreement()) {
        try renamer.renameReferences(
            allocator,
            references,
            asset_new_name,
        );
    } else {
        std.debug.print("U said no FYI\n", .{});
    }
}

fn validateArguments(arguments: Arguments) bool {
    if (arguments.is_asset_sync == true and arguments.is_reference_replacement == true) {
        std.debug.print("ERROR: You must specify only one operation type per execution\n", .{});
        return false;
    }

    if (arguments.is_asset_sync == true) {
        // Program that runned with "-sync" param, must have "-xcassets" path
        const is_have_xcassets_path = arguments.xcassets_path != null;

        if (!is_have_xcassets_path) {
            std.debug.print("ERROR: Add -xcassets path\n", .{});
        }

        return is_have_xcassets_path;
    }

    if (arguments.is_reference_replacement == true) {
        // Program that runned with "-replace" param, must have at least "-old" asset name for search
        // and project path "-project" param

        // Program that runned without "-new" asset name param - just show references without replacement

        const is_have_project_path = arguments.project_path != null;
        if (!is_have_project_path) {
            std.debug.print("ERROR: Add -project path\n", .{});
            return false;
        }

        const is_have_old_name = arguments.asset_name != null;
        if (!is_have_old_name) {
            std.debug.print("ERROR: Add -old asset name\n", .{});
            return false;
        }

        return is_have_project_path and is_have_old_name;
    }

    std.debug.print("ERROR: You must specify type of operation: -sync or -replace\n", .{});
    return false;
}

fn printArguments(arguments: Arguments) void {
    if (arguments.is_asset_sync == true) {
        std.debug.print("XCAssets path: {?s}\n", .{arguments.xcassets_path});
        std.debug.print("Asset sync: true\n\n", .{});
    }

    if (arguments.is_reference_replacement == true) {
        std.debug.print("Path: {?s}\n", .{arguments.project_path});
        std.debug.print("Asset: {?s}\n", .{arguments.asset_name});
        std.debug.print("Asset new name: {?s}\n\n", .{arguments.asset_new_name});
    }
}

fn getUserAgreement() bool {
    std.debug.print("Perform changes? (y/N): ", .{});

    const stdin = std.io.getStdIn();
    defer stdin.close();
    const reader = stdin.reader();

    var buf: [1024]u8 = undefined;
    const user_input = reader.readUntilDelimiterOrEof(&buf, '\n') catch return false;
    if (user_input) |input| {
        return std.mem.eql(u8, input, "y");
    }

    return false;
}

fn printAssetReference(c: *chameleon.RuntimeChameleon, asset: AssetReference) !void {
    for (asset.occurences) |occur| {
        var line_content = occur.line_content;
        const before_asset = line_content[0..occur.position.start];
        const asset_content = line_content[occur.position.start..occur.position.end];
        const after_asset = line_content[occur.position.end..];

        try c.magenta().bold().printOut("Line: {d}\nPath: {s}\n", .{ occur.line, asset.path });
        try c.white().printOut("{s}", .{std.mem.trim(u8, before_asset, " ")});
        try c.green().bold().printOut("{s}", .{std.mem.trim(u8, asset_content, " ")});
        try c.white().printOut("{s}\n\n", .{std.mem.trim(u8, after_asset, " ")});
    }
}
