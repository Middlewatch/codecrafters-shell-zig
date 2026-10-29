const std = @import("std");

pub fn tokenizeInput(allocator: std.mem.Allocator, line: []const u8) ![]const []const u8 {
    var list: std.ArrayList([]const u8) = .empty;
    var itr = std.mem.tokenizeScalar(u8, line, ' ');
    while (itr.next()) |input| {
        try list.append(allocator, input);
    }
    return try list.toOwnedSlice(allocator);
}
