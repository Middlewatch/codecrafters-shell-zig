const std = @import("std");
const path = @import("path.zig");

pub fn main(init: std.process.Init) !void {
    var stdin_buffer: [4096]u8 = undefined;
    var stdin = std.Io.File.stdin().readerStreaming(init.io, &stdin_buffer);
    var stdout = std.Io.File.stdout().writer(init.io, &.{});
    var arena = std.heap.ArenaAllocator.init(init.gpa);
    defer arena.deinit();

    while (true) {
        defer _ = arena.reset(.retain_capacity);
        // prompt
        try stdout.interface.print("$ ", .{});
        // stores user input into command
        const command = try stdin.interface.takeDelimiter('\n');
        // need to refactor this part for the builtins enum
        if (std.mem.eql(u8, command.?, "exit")) {
            break;
        } else if (std.mem.startsWith(u8, command.?, "echo")) {
            try stdout.interface.print("{s}\n", .{command.?[5..]});
        } else if (std.mem.startsWith(u8, command.?, "type")) {
            if (std.mem.eql(u8, command.?[5..], "echo") or std.mem.eql(u8, command.?[5..], "exit") or std.mem.eql(u8, command.?[5..], "type")) {
                try stdout.interface.print("{s} is a shell builtin\n", .{command.?[5..]});
            } else {
                const name = try path.checkInPath(init.io, arena.allocator(), init.environ_map, command.?[5..]);
                if (name) |found| {
                    try stdout.interface.print("{s} is {s}\n", .{ command.?, found });
                } else {
                    try stdout.interface.print("{s}: not found\n", .{command.?});
                }
            }
        } else {
            try stdout.interface.print("{s}: command not found\n", .{command.?});
        }
    }
}
