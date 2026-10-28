const std = @import("std");
const lookup = @import("lookup.zig");
const builtins = @import("builtins.zig");

pub fn main(init: std.process.Init) !void {
    var stdin_buffer: [4096]u8 = undefined;
    var stdin = std.Io.File.stdin().readerStreaming(init.io, &stdin_buffer);
    var stdout = std.Io.File.stdout().writer(init.io, &.{});
    var arena = std.heap.ArenaAllocator.init(init.gpa);
    defer arena.deinit();

    while (true) {
        defer _ = arena.reset(.retain_capacity);
        var list: std.ArrayList([]const u8) = .empty;
        // prompt
        try stdout.interface.print("$ ", .{});
        const line = try stdin.interface.takeDelimiter('\n') orelse break;
        var itr = std.mem.tokenizeScalar(u8, line, ' ');
        while (itr.next()) |input| {
            try list.append(arena.allocator(), input);
        }
        if (list.items.len == 0) continue;
        if (builtins.Builtin.fromString(list.items[0])) |command| {
            switch (command) {
                .exit => break,
                .echo => try builtins.echoCmd(&stdout.interface, list.items),
                .type => try builtins.typeCmd(list.items, init.io, arena.allocator(), init.environ_map, &stdout.interface),
                .pwd => try builtins.pwdCmd(init.io, &stdout.interface),
                .cd => try builtins.cdCmd(init.io, &stdout.interface, list.items),
            }
        } else {
            if (try lookup.find(init.io, arena.allocator(), init.environ_map, list.items[0]) == null) {
                try stdout.interface.print("{s}: command not found\n", .{list.items[0]});
            } else {
                try lookup.runProgram(init.io, list.items);
            }
        }
    }
}
