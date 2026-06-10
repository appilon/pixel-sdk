//! Small monotonic-clock and sleep helpers.

const std = @import("std");

pub fn monotonicNanoseconds() u64 {
    var now: std.c.timespec = undefined;
    std.debug.assert(std.c.clock_gettime(.MONOTONIC, &now) == 0);
    return @as(u64, @intCast(now.sec)) * std.time.ns_per_s +
        @as(u64, @intCast(now.nsec));
}

pub fn sleepNanoseconds(nanoseconds: u64) void {
    var remaining = timespecFromNanoseconds(nanoseconds);
    // EINTR retries remain bounded by the requested sleep under normal signal delivery.
    while (true) {
        switch (std.c.errno(std.c.nanosleep(&remaining, &remaining))) {
            .SUCCESS => return,
            .INTR => continue,
            else => unreachable,
        }
    }
}

pub fn sleepMilliseconds(milliseconds: u64) void {
    const nanoseconds = std.math.mul(u64, milliseconds, std.time.ns_per_ms) catch
        std.math.maxInt(u64);
    sleepNanoseconds(nanoseconds);
}

fn timespecFromNanoseconds(nanoseconds: u64) std.c.timespec {
    return .{
        .sec = @intCast(nanoseconds / std.time.ns_per_s),
        .nsec = @intCast(nanoseconds % std.time.ns_per_s),
    };
}

test "nanoseconds split into normalized timespec fields" {
    const value = timespecFromNanoseconds(2 * std.time.ns_per_s + 345);
    try std.testing.expectEqual(@as(@TypeOf(value.sec), 2), value.sec);
    try std.testing.expectEqual(@as(@TypeOf(value.nsec), 345), value.nsec);
}
