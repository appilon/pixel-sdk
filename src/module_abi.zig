//! Stable C ABI shared by Pixel hosts and dynamically loaded modules.

const std = @import("std");

pub const abi_version: u32 = 1;
pub const query_symbol: [:0]const u8 = "pixel_module_query";

pub const Result = enum(u32) {
    ok = 0,
    incompatible_abi = 1,
    invalid_phase = 2,
    capacity_exceeded = 3,
    invalid_argument = 4,
    initialization_failed = 5,
};

pub const ResourceType = enum(u32) {
    device_memory = 1,
    buffer = 2,
    pipeline_layout = 3,
    pipeline = 4,
};

pub const invalid_websocket_id: u32 = std.math.maxInt(u32);

pub const VkInstance = ?*anyopaque;
pub const VkPhysicalDevice = ?*anyopaque;
pub const VkDevice = ?*anyopaque;
pub const VkRenderPass = ?*anyopaque;
pub const VkCommandBuffer = ?*anyopaque;
pub const VkHandle = ?*anyopaque;

pub const GetInstanceProcAddressFn = *const fn (
    VkInstance,
    [*:0]const u8,
) callconv(.c) ?*const fn () callconv(.c) void;

pub const AllocateFn = *const fn (
    userdata: ?*anyopaque,
    size: u64,
    alignment: u32,
) callconv(.c) ?*anyopaque;

pub const TrackResourceFn = *const fn (
    userdata: ?*anyopaque,
    resource_type: ResourceType,
    handle: VkHandle,
) callconv(.c) Result;

pub const LogFn = *const fn (
    userdata: ?*anyopaque,
    message: [*]const u8,
    message_length: u32,
) callconv(.c) void;

pub const WebSocketMessageKind = enum(u32) {
    text = 1,
    binary = 2,
};

pub const WebSocketSendStatus = enum(u32) {
    ok = 0,
    invalid_handle = 1,
    closed = 2,
    queue_full = 3,
    message_too_large = 4,
};

pub const WebSocketPollStatus = enum(u32) {
    empty = 0,
    message = 1,
    truncated = 2,
    closed = 3,
    invalid_handle = 4,
    error_state = 5,
};

pub const WebSocketHandle = extern struct {
    id: u32,
    generation: u32,
};

pub const WebSocketOpenInfo = extern struct {
    host: ?[*:0]const u8,
    path: ?[*:0]const u8,
    port: u16,
    tls: u32,
    max_message_bytes: u32,
    flags: u32,
};

pub const WebSocketPollResult = extern struct {
    status: WebSocketPollStatus,
    kind: WebSocketMessageKind,
    bytes_written: u32,
    bytes_available: u32,
};

pub const WebSocketOpenFn = *const fn (
    userdata: ?*anyopaque,
    info: *const WebSocketOpenInfo,
) callconv(.c) WebSocketHandle;

pub const WebSocketCloseFn = *const fn (
    userdata: ?*anyopaque,
    handle: WebSocketHandle,
) callconv(.c) void;

pub const WebSocketSendFn = *const fn (
    userdata: ?*anyopaque,
    handle: WebSocketHandle,
    kind: WebSocketMessageKind,
    data: [*]const u8,
    length: u32,
) callconv(.c) WebSocketSendStatus;

pub const WebSocketPollFn = *const fn (
    userdata: ?*anyopaque,
    handle: WebSocketHandle,
    output: [*]u8,
    output_capacity: u32,
) callconv(.c) WebSocketPollResult;

pub const HostApi = extern struct {
    abi_version: u32,
    struct_size: u32,
    userdata: ?*anyopaque,
    allocate: AllocateFn,
    track_resource: TrackResourceFn,
    log: LogFn,
    get_instance_proc_address: GetInstanceProcAddressFn,
    vk_instance: VkInstance,
    vk_physical_device: VkPhysicalDevice,
    vk_device: VkDevice,
    render_pass: VkRenderPass,
    websocket_open: ?WebSocketOpenFn,
    websocket_close: ?WebSocketCloseFn,
    websocket_send: ?WebSocketSendFn,
    websocket_poll: ?WebSocketPollFn,
};

pub const FrameInfo = extern struct {
    frame_index: u64,
    predicted_display_time_ns: i64,
    delta_time_ns: u64,
};

pub const ViewRenderContext = extern struct {
    command_buffer: VkCommandBuffer,
    view_index: u32,
    view_count: u32,
    width: u32,
    height: u32,
    view: [16]f32,
    projection: [16]f32,
};

pub const UpdateFn = *const fn (
    module_context: ?*anyopaque,
    frame: *const FrameInfo,
) callconv(.c) void;

pub const RenderViewFn = *const fn (
    module_context: ?*anyopaque,
    frame: *const FrameInfo,
    view: *const ViewRenderContext,
) callconv(.c) void;

pub const ModuleApi = extern struct {
    abi_version: u32,
    struct_size: u32,
    module_context: ?*anyopaque,
    update: ?UpdateFn,
    render_view: ?RenderViewFn,
};

pub const QueryFn = *const fn (
    host_api: *const HostApi,
    module_api: *ModuleApi,
) callconv(.c) Result;

pub fn hostCompatible(host_api: *const HostApi) bool {
    return host_api.abi_version == abi_version and
        host_api.struct_size >= @sizeOf(HostApi);
}

pub fn moduleCompatible(module_api: *const ModuleApi) bool {
    return module_api.abi_version == abi_version and
        module_api.struct_size >= @sizeOf(ModuleApi);
}

test "ABI enums use explicit 32-bit backing" {
    try std.testing.expectEqual(@as(usize, 4), @sizeOf(Result));
    try std.testing.expectEqual(@as(usize, 4), @sizeOf(ResourceType));
    try std.testing.expectEqual(@as(usize, 4), @sizeOf(WebSocketMessageKind));
    try std.testing.expectEqual(@as(usize, 4), @sizeOf(WebSocketSendStatus));
    try std.testing.expectEqual(@as(usize, 4), @sizeOf(WebSocketPollStatus));
}

test "ABI structs have stable 64-bit layouts" {
    if (@sizeOf(usize) != 8) return error.SkipZigTest;

    try std.testing.expectEqual(@as(usize, 112), @sizeOf(HostApi));
    try std.testing.expectEqual(@as(usize, 24), @sizeOf(FrameInfo));
    try std.testing.expectEqual(@as(usize, 152), @sizeOf(ViewRenderContext));
    try std.testing.expectEqual(@as(usize, 32), @sizeOf(ModuleApi));
    try std.testing.expectEqual(@as(usize, 8), @sizeOf(WebSocketHandle));
    try std.testing.expectEqual(@as(usize, 32), @sizeOf(WebSocketOpenInfo));
    try std.testing.expectEqual(@as(usize, 16), @sizeOf(WebSocketPollResult));
    try std.testing.expectEqual(@as(usize, 8), @alignOf(HostApi));
    try std.testing.expectEqual(@as(usize, 8), @alignOf(ModuleApi));
    try std.testing.expectEqual(@as(usize, 4), @alignOf(WebSocketHandle));
    try std.testing.expectEqual(@as(usize, 8), @alignOf(WebSocketOpenInfo));
    try std.testing.expectEqual(@as(usize, 4), @alignOf(WebSocketPollResult));
}

test "compatibility requires matching version and sufficient size" {
    var host_api: HostApi = undefined;
    host_api.abi_version = abi_version;
    host_api.struct_size = @sizeOf(HostApi);
    try std.testing.expect(hostCompatible(&host_api));

    host_api.abi_version += 1;
    try std.testing.expect(!hostCompatible(&host_api));
}

test "invalid websocket handle sentinel is outside valid websocket ids" {
    const invalid = WebSocketHandle{ .id = invalid_websocket_id, .generation = 0 };
    try std.testing.expectEqual(std.math.maxInt(u32), invalid.id);
    try std.testing.expectEqual(@as(u32, 0), invalid.generation);
}
