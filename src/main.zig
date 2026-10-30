const std = @import("std");
const lookup = @import("lookup.zig");
const builtins = @import("builtins.zig");
const tokenizer = @import("tokenizer.zig");

pub fn main(init: std.process.Init) !void {
    var stdin_buffer: [4096]u8 = undefined;
    var stdin = std.Io.File.stdin().readerStreaming(init.io, &stdin_buffer);
    var stdout = std.Io.File.stdout().writer(init.io, &.{});
    var stderr = std.Io.File.stderr().writer(init.io, &.{});
    var arena = std.heap.ArenaAllocator.init(init.gpa);
    defer arena.deinit();

    while (true) {
        defer _ = arena.reset(.retain_capacity);
        // prompt
        try stdout.interface.print("$ ", .{});
        const line = try stdin.interface.takeDelimiter('\n') orelse break;
        const command = try tokenizer.tokenizeInput(arena.allocator(), init.environ_map, line);
        const argv = command.argv; //because im too lazy to rename rn
        // variables below are for the > redirect handling
        var out: *std.Io.Writer = &stdout.interface;
        var redirect_file: ?std.Io.File = null;
        var file_writer: std.Io.File.Writer = undefined;

        if (argv.len == 0) continue;
        if (command.stdout_path) |path| {
            const file = try std.Io.Dir.cwd().createFile(init.io, path, .{});
            redirect_file = file;
            file_writer = file.writer(init.io, &.{});
            out = &file_writer.interface;
        }
        defer if (redirect_file) |f| f.close(init.io);
        if (builtins.Builtin.fromString(argv[0])) |builtin| {
            switch (builtin) {
                .exit => break,
                .echo => try builtins.echoCmd(out, argv),
                .type => try builtins.typeCmd(argv, init.io, arena.allocator(), init.environ_map, out),
                .pwd => try builtins.pwdCmd(init.io, out),
                .cd => try builtins.cdCmd(init.io, &stderr.interface, argv),
            }
        } else {
            if (try lookup.find(init.io, arena.allocator(), init.environ_map, argv[0]) == null) {
                try stderr.interface.print("{s}: command not found\n", .{argv[0]});
            } else {
                try lookup.runProgram(init.io, argv, redirect_file);
            }
        }
    }
}
