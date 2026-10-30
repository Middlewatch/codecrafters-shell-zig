const std = @import("std");
const Mode = enum {
    normal,
    single_quote,
    double_quote,
    backslash_escape,
    double_quote_escape,
};

const Command = struct {
    argv: []const []const u8,
    stdout_path: ?[]const u8 = null,
};

fn tokenizeHelper(allocator: std.mem.Allocator, environ: *const std.process.Environ.Map, word: []const u8) ![]const u8 {
    if (std.mem.eql(u8, word, "~") or std.mem.startsWith(u8, word, "~/")) {
        // orelse return word should return the ~ literal and the kernel will handle the error if home isnt set
        const envHome = environ.get("HOME") orelse return word;
        // word [1..] should hold everything bolted onto a path starting with ~
        return try std.mem.concat(allocator, u8, &.{ envHome, word[1..] });
    }
    return word;
}

pub fn tokenizeInput(allocator: std.mem.Allocator, environ: *const std.process.Environ.Map, line: []const u8) !Command {
    var list: std.ArrayList([]const u8) = .empty;
    var mode: Mode = .normal;
    var word: std.ArrayList(u8) = .empty;
    const stdout_path: ?[]const u8 = null; //flipping to variable when needed
    for (line) |input| {
        switch (mode) {
            .normal => {
                switch (input) {
                    ' ' => {
                        if (word.items.len != 0) {
                            const finished = try word.toOwnedSlice(allocator);
                            const expanded = try tokenizeHelper(allocator, environ, finished);
                            try list.append(allocator, expanded);
                        }
                    },
                    '\'' => mode = .single_quote,
                    '"' => mode = .double_quote,
                    '\\' => mode = .backslash_escape,
                    else => try word.append(allocator, input),
                }
            },
            .single_quote => {
                switch (input) {
                    '\'' => mode = .normal,
                    else => try word.append(allocator, input),
                }
            },
            .double_quote => {
                switch (input) {
                    '"' => mode = .normal,
                    '\\' => mode = .double_quote_escape,
                    else => try word.append(allocator, input),
                }
            },
            .backslash_escape => {
                try word.append(allocator, input);
                mode = .normal;
            },
            .double_quote_escape => {
                switch (input) {
                    '\\', '"' => try word.append(allocator, input),
                    else => {
                        try word.append(allocator, '\\');
                        try word.append(allocator, input);
                    },
                }
                mode = .double_quote;
            },
        }
    }
    if (word.items.len != 0) {
        const finished = try word.toOwnedSlice(allocator);
        const expanded = try tokenizeHelper(allocator, environ, finished);
        try list.append(allocator, expanded);
    }
    return .{ .argv = try list.toOwnedSlice(allocator), .stdout_path = stdout_path };
}
