const std = @import("std");

fn tokenizeHelper(allocator: std.mem.Allocator, environ: *const std.process.Environ.Map, word: []const u8) ![]const u8 {
    if (std.mem.eql(u8, word, "~") or std.mem.startsWith(u8, word, "~/")) {
        // orelse return word should return the ~ literal and the kernel will handle the error if home isnt set
        const envHome = environ.get("HOME") orelse return word;
        // word [1..] should hold everything bolted onto a path starting with ~
        return try std.mem.concat(allocator, u8, &.{ envHome, word[1..] });
    }
    return word;
}

pub fn tokenizeInput(allocator: std.mem.Allocator, environ: *const std.process.Environ.Map, line: []const u8) ![]const []const u8 {
    var list: std.ArrayList([]const u8) = .empty;
    var itr = std.mem.tokenizeScalar(u8, line, ' ');
    while (itr.next()) |input| {
        const word = try tokenizeHelper(allocator, environ, input);
        try list.append(allocator, word);
    }
    return try list.toOwnedSlice(allocator);
}
