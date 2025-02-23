const std = @import("std");
const chameleon = @import("chameleon");
const finder = @import("asset_finder.zig");
const AssetReference = @import("AssetReference.zig");
const renamer = @import("asset_renamer.zig");
const Arguments = @import("Arguments.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    const argv = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, argv);

    if (argv.len < 7) {
        std.debug.print("Add some arguments pls\n", .{});
        return;
    }

    var arguments = try Arguments.parse(
        allocator,
        argv,
    );
    defer arguments.deinit();

    printArguments(arguments);

    var c = chameleon.initRuntime(.{ .allocator = allocator });
    defer c.deinit();

    const project_path = arguments.project_path orelse {
        std.debug.print("Project path is null\n", .{});
        return;
    };

    const proj_dir = try std.fs.openDirAbsolute(
        project_path,
        .{ .iterate = true },
    );

    const asset_name = arguments.asset_name orelse {
        std.debug.print("Asset name is null\n", .{});
        return;
    };
    const references = try finder.findReferences(
        allocator,
        asset_name,
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

    const asset_new_name = arguments.asset_new_name orelse {
        std.debug.print("New asset name is null\n", .{});
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

fn printArguments(arguments: Arguments) void {
    std.debug.print("Path: {?s}\n", .{arguments.project_path});
    std.debug.print("Asset: {?s}\n", .{arguments.asset_name});
    std.debug.print("Asset new name: {?s}\n\n", .{arguments.asset_new_name});
}

fn getUserAgreement() bool {
    std.debug.print("Perform changes? (y/n): ", .{});

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
