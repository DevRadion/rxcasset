const Self = @This();

const std = @import("std");
const arg_parser = @import("arg_parser.zig");

allocator: std.mem.Allocator,

is_asset_sync: ?bool = null,
is_reference_replacement: ?bool = null,

project_path: ?[]u8 = null,
xcassets_path: ?[]u8 = null,

asset_name: ?[]u8 = null,
asset_new_name: ?[]u8 = null,

pub fn parse(allocator: std.mem.Allocator, argv: [][:0]u8) !Self {
    var arg_map = try arg_parser.parse(allocator, &argv);
    defer arg_map.deinit();

    var arguments = Self{
        .allocator = allocator,
    };

    if (arg_map.get("-project")) |path|
        arguments.project_path = try allocator.dupe(u8, path);

    if (arg_map.get("-xcassets")) |path|
        arguments.xcassets_path = try allocator.dupe(u8, path);

    if (arg_map.get("-sync") != null)
        arguments.is_asset_sync = true;

    if (arg_map.get("-replace") != null)
        arguments.is_reference_replacement = true;

    if (arg_map.get("-old")) |asset|
        arguments.asset_name = try allocator.dupe(u8, asset);

    if (arg_map.get("-new")) |new|
        arguments.asset_new_name = try allocator.dupe(u8, new);

    return arguments;
}

pub fn deinit(arguments: *Self) void {
    if (arguments.project_path) |path| arguments.allocator.free(path);
    if (arguments.xcassets_path) |path| arguments.allocator.free(path);
    if (arguments.asset_name) |asset| arguments.allocator.free(asset);
    if (arguments.asset_new_name) |new| arguments.allocator.free(new);
}
