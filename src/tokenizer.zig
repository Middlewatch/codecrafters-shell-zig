const std = @import("std");
const Mode = enum {
    normal,
    single_quote,
    double_quote,
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

pub fn tokenizeInput(allocator: std.mem.Allocator, environ: *const std.process.Environ.Map, line: []const u8) ![]const []const u8 {
    var list: std.ArrayList([]const u8) = .empty;
    var mode: Mode = .normal;
    var word: std.ArrayList(u8) = .empty;
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
                    else => try word.append(allocator, input),
                }
            },
        }
    }
    if (word.items.len != 0) {
        const finished = try word.toOwnedSlice(allocator);
        const expanded = try tokenizeHelper(allocator, environ, finished);
        try list.append(allocator, expanded);
    }
    return try list.toOwnedSlice(allocator);
}
