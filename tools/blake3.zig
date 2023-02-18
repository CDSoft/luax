// This file is part of luax.
//
// luax is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// luax is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with luax.  If not, see <https://www.gnu.org/licenses/>.
//
// For further information about luax you can visit
// http://cdelord.fr/luax

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
