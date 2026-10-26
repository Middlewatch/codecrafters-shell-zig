const std = @import("std");

pub const Builtin = enum {exit, echo, type};

pub fn typeCommand(args: []const []const u8, out: "std.Io.Writer", )
