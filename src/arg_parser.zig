const std = @import("std");

pub fn parse(allocator: std.mem.Allocator, argv: *const [][:0]u8) !std.StringHashMap([]u8) {
    var map = std.StringHashMap([]u8).init(allocator);

    for (0..argv.len) |i| {
        const next_idx = i + 1;
        if (argv.*.len < next_idx) break;

        // Check current argument for parameter sign
        // If argument starts with "-" - it's parameter
        const is_param = checkParameterSign(argv.*[i]);

        // If current idx + 1 (next arg) is less than argv lenght,
        const is_single_param = if (next_idx < argv.len)
            // check next arg for parameter sign and if both
            // current and next arg is params - current param is single because it has no value
            checkParameterSign(argv.*[next_idx]) and is_param
        else
            // If current arg is last and it's parameter is also single parameter.
            is_param;

        if (is_single_param) {
            try map.put(argv.*[i], argv.*[i]);
        } else if (is_param) {
            try map.put(argv.*[i], argv.*[next_idx]);
        }
    }

    return map;
}

fn checkParameterSign(arg: []u8) bool {
    return std.mem.startsWith(u8, arg, "-");
}
