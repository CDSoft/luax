const std = @import("std");
const Blake3 = std.crypto.hash.Blake3;
const hex = std.fmt.fmtSliceHexLower;

pub fn main() !void {
    const stdin = std.io.getStdIn().reader();
    const stdout = std.io.getStdOut().writer();

    var input : [4*1024*1024]u8 = undefined;
    var output : [512/8]u8 = undefined;

    var n = try stdin.readAll(&input);
    Blake3.hash(input[0..n-1], &output, .{});

    var i: usize = 0;
    while (i < output.len) : (i += 1) {
        try stdout.print("\\x{s}", .{hex(output[i..i+1])});
    }
    try stdout.print("\n", .{});
}
