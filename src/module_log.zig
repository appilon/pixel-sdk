//! Allocation-free structured logging for Pixel native modules.

const std = @import("std");
const abi = @import("module_abi");
const time = @import("time");

const event_buffer_bytes: usize = 512;

pub fn write(host: *const abi.HostApi, message: []const u8) void {
    host.log(host.userdata, message.ptr, @intCast(message.len));
}

pub fn event(
    host: *const abi.HostApi,
    level: []const u8,
    component: []const u8,
    event_name: []const u8,
) void {
    var buffer: [event_buffer_bytes]u8 = undefined;
    const message = formatEvent(
        &buffer,
        time.monotonicNanoseconds(),
        level,
        component,
        event_name,
    ) catch return;
    write(host, message);
}

fn formatEvent(
    buffer: []u8,
    timestamp_ns: u64,
    level: []const u8,
    component: []const u8,
    event_name: []const u8,
) ![]const u8 {
    if (!isIdentifier(level) or
        !isIdentifier(component) or
        !isIdentifier(event_name))
    {
        return error.InvalidIdentifier;
    }
    return std.fmt.bufPrint(
        buffer,
        "{{\"ts_monotonic_ns\":{d},\"level\":\"{s}\"," ++
            "\"component\":\"{s}\",\"event\":\"{s}\"}}",
        .{ timestamp_ns, level, component, event_name },
    );
}

fn isIdentifier(value: []const u8) bool {
    if (value.len == 0) return false;
    for (value) |byte| {
        if (!std.ascii.isAlphanumeric(byte) and
            byte != '.' and byte != '_' and byte != '-')
        {
            return false;
        }
    }
    return true;
}

test "event envelope is stable newline-delimited JSON payload" {
    var buffer: [event_buffer_bytes]u8 = undefined;
    const message = try formatEvent(
        &buffer,
        123,
        "info",
        "quest.module.demo",
        "module.ready",
    );
    try std.testing.expectEqualStrings(
        "{\"ts_monotonic_ns\":123,\"level\":\"info\"," ++
            "\"component\":\"quest.module.demo\",\"event\":\"module.ready\"}",
        message,
    );
}

test "event identifiers reject characters that require JSON escaping" {
    var buffer: [event_buffer_bytes]u8 = undefined;
    try std.testing.expectError(
        error.InvalidIdentifier,
        formatEvent(&buffer, 123, "info", "quest.module", "bad\"event"),
    );
}
