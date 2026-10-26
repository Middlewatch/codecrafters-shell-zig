const std = @import("std");

pub fn checkInPath(io: std.Io, allocator: std.mem.Allocator, environ: *const std.process.Environ.Map, name: []const u8) !?[]const u8 {
    // since environ.get returns ?[]const u8 we have to handle the null case (useful)
    const path = environ.get("PATH") orelse return null;
    // ok now I understand that path.delimiter is what makes this work on windows and linux
    var itr = std.mem.tokenizeScalar(u8, path, std.fs.path.delimiter);
    while (itr.next()) |dirname| {
        // the allocator is needed to get enough bytes to store the directory name then cleared below, from what I understand
        // a gpa here would need to be explicitly dumped or would grow forever
        const full_path = try std.fs.path.join(allocator, &.{ dirname, name });
        // asks the filesystem directly not sure if more edge case detection is needed or not, assume that a named directory would
        // be a false positive
        std.Io.Dir.cwd().access(io, full_path, .{ .execute = true }) catch continue;
        return full_path;
    }
    return null;
}
