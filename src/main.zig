const std = @import("std");
const lookup = @import("lookup.zig");
const builtins = @import("builtins.zig");
const tokenizer = @import("tokenizer.zig");

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
        const line = try stdin.interface.takeDelimiter('\n') orelse break;

        const argv = try tokenizer.tokenizeInput(arena.allocator(), line);
        if (argv.len == 0) continue;
        if (builtins.Builtin.fromString(argv[0])) |command| {
            switch (command) {
                .exit => break,
                .echo => try builtins.echoCmd(&stdout.interface, argv),
                .type => try builtins.typeCmd(argv, init.io, arena.allocator(), init.environ_map, &stdout.interface),
                .pwd => try builtins.pwdCmd(init.io, &stdout.interface),
                .cd => try builtins.cdCmd(init.io, &stdout.interface, argv),
            }
        } else {
            if (try lookup.find(init.io, arena.allocator(), init.environ_map, argv[0]) == null) {
                try stdout.interface.print("{s}: command not found\n", .{argv[0]});
            } else {
                try lookup.runProgram(init.io, argv);
            }
        }
    }
}
