const std = @import("std");

pub fn parse(allocator: std.mem.Allocator, argv: *const [][:0]u8) !std.StringHashMap([]u8) {
    var map = std.StringHashMap([]u8).init(allocator);

    for (0..argv.len) |i| {
        const next_idx = i + 1;
        if (argv.*.len < next_idx) break;

        if (std.mem.startsWith(u8, argv.*[i], "-")) {
            try map.put(argv.*[i], argv.*[next_idx]);
        }
    }

    return map;
}
