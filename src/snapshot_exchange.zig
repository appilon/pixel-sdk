//! Single-producer, single-consumer exchange for the newest complete snapshot.

const std = @import("std");

const dirty_bit: u8 = 0x80;
const index_mask: u8 = 0x03;

pub fn SnapshotExchange(comptime T: type) type {
    return struct {
        const Self = @This();

        slots: [3]T,
        producer_index: u8 = 1,
        consumer_index: u8 = 0,
        middle: std.atomic.Value(u8) = std.atomic.Value(u8).init(2),

        pub fn init(initial: T) Self {
            return .{ .slots = .{ initial, initial, initial } };
        }

        pub fn write(self: *Self) *T {
            return &self.slots[self.producer_index];
        }

        pub fn publish(self: *Self) void {
            const previous = self.middle.swap(self.producer_index | dirty_bit, .acq_rel);
            self.producer_index = previous & index_mask;
        }

        pub fn latch(self: *Self) *const T {
            if (self.middle.load(.acquire) & dirty_bit != 0) {
                const previous = self.middle.swap(self.consumer_index, .acq_rel);
                self.consumer_index = previous & index_mask;
            }
            return self.read();
        }

        pub fn read(self: *const Self) *const T {
            return &self.slots[self.consumer_index];
        }
    };
}

test "latest published snapshot replaces an older pending snapshot" {
    var exchange = SnapshotExchange(u64).init(1);
    try std.testing.expectEqual(@as(u64, 1), exchange.latch().*);

    exchange.write().* = 2;
    exchange.publish();
    exchange.write().* = 3;
    exchange.publish();

    try std.testing.expectEqual(@as(u64, 3), exchange.latch().*);
}

test "latched snapshot stays immutable while producer publishes" {
    const Snapshot = struct {
        sequence: u64,
        inverse: u64,
    };
    var exchange = SnapshotExchange(Snapshot).init(.{
        .sequence = 1,
        .inverse = ~@as(u64, 1),
    });

    const first = exchange.latch();
    exchange.write().* = .{ .sequence = 2, .inverse = ~@as(u64, 2) };
    exchange.publish();

    try std.testing.expectEqual(@as(u64, 1), first.sequence);
    try std.testing.expectEqual(~first.sequence, first.inverse);
    const second = exchange.latch();
    try std.testing.expectEqual(@as(u64, 2), second.sequence);
    try std.testing.expectEqual(~second.sequence, second.inverse);
}

test "concurrent producer and consumer never observe a torn snapshot" {
    const Snapshot = struct {
        sequence: u64,
        inverse: u64,
    };
    const Exchange = SnapshotExchange(Snapshot);
    const State = struct {
        exchange: Exchange,
        done: std.atomic.Value(bool) = std.atomic.Value(bool).init(false),
    };
    const Worker = struct {
        fn run(state: *State) void {
            var sequence: u64 = 1;
            while (sequence <= 100_000) : (sequence += 1) {
                state.exchange.write().* = .{
                    .sequence = sequence,
                    .inverse = ~sequence,
                };
                state.exchange.publish();
            }
            state.done.store(true, .release);
        }
    };

    var state = State{
        .exchange = Exchange.init(.{ .sequence = 0, .inverse = ~@as(u64, 0) }),
    };
    const producer = try std.Thread.spawn(.{}, Worker.run, .{&state});
    defer producer.join();

    var previous: u64 = 0;
    var observation_count: u32 = 0;
    while (!state.done.load(.acquire) and
        observation_count < 1_000_000) : (observation_count += 1)
    {
        const snapshot = state.exchange.latch();
        try std.testing.expectEqual(~snapshot.sequence, snapshot.inverse);
        try std.testing.expect(snapshot.sequence >= previous);
        previous = snapshot.sequence;
    }
    try std.testing.expect(state.done.load(.acquire));
    const final = state.exchange.latch();
    try std.testing.expectEqual(@as(u64, 100_000), final.sequence);
    try std.testing.expectEqual(~final.sequence, final.inverse);
    try std.testing.expect(final.sequence >= previous);
}
