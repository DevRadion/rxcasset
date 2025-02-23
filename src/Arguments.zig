const Self = @This();

const std = @import("std");
const arg_parser = @import("arg_parser.zig");

allocator: std.mem.Allocator,
project_path: ?[]u8 = null,
asset_name: ?[]u8 = null,
asset_new_name: ?[]u8 = null,

pub fn parse(allocator: std.mem.Allocator, argv: [][:0]u8) !Self {
    var arg_map = try arg_parser.parse(allocator, &argv);
    defer arg_map.deinit();

    var arguments = Self{
        .allocator = allocator,
    };

    if (arg_map.get("-ppath")) |path|
        arguments.project_path = try allocator.dupe(u8, path);

    if (arg_map.get("-asset")) |asset|
        arguments.asset_name = try allocator.dupe(u8, asset);

    if (arg_map.get("-new")) |new|
        arguments.asset_new_name = try allocator.dupe(u8, new);

    return arguments;
}

pub fn deinit(arguments: *Self) void {
    var deref = arguments.*;

    if (arguments.*.project_path) |path| deref.allocator.free(path);
    if (arguments.*.asset_name) |asset| deref.allocator.free(asset);
    if (arguments.*.asset_new_name) |new| deref.allocator.free(new);

    deref = undefined;
}
