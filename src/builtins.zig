const std = @import("std");
const lookup = @import("lookup.zig");

pub const Builtin = enum {
    exit,
    echo,
    type,

    pub fn fromString(input: []const u8) ?Builtin {
        return std.meta.stringToEnum(Builtin, input);
    }
};

pub fn echoCmd(out: *std.Io.Writer, args: []const []const u8) !void {
    for (args[1..], 0..) |arg, i| {
        if (i != 0) {
            try out.writeByte(' ');
        }
        try out.print("{s}", .{arg});
    }
    try out.writeByte('\n');
}

pub fn typeCmd(args: []const []const u8, io: std.Io, allocator: std.mem.Allocator, environ: *const std.process.Environ.Map, out: *std.Io.Writer) !void {
    if (args.len < 2) return;
    // There is probably a cleaner way to do this comparison, revisit later
    if (Builtin.fromString(args[1]) != null) {
        try out.print("{s} is a shell builtin\n", .{args[1]});
    } else {
        // this is the look and see if its in PATH handler
        const name = try lookup.find(io, allocator, environ, args[1]);
        if (name) |found| {
            try out.print("{s} is {s}\n", .{ args[1], found });
        } else {
            try out.print("{s}: not found\n", .{args[1]});
        }
    }
}
