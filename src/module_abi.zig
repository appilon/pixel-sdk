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
    update: UpdateFn,
    render_view: RenderViewFn,
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
}

test "ABI structs have stable 64-bit layouts" {
    if (@sizeOf(usize) != 8) return error.SkipZigTest;

    try std.testing.expectEqual(@as(usize, 80), @sizeOf(HostApi));
    try std.testing.expectEqual(@as(usize, 24), @sizeOf(FrameInfo));
    try std.testing.expectEqual(@as(usize, 152), @sizeOf(ViewRenderContext));
    try std.testing.expectEqual(@as(usize, 32), @sizeOf(ModuleApi));
    try std.testing.expectEqual(@as(usize, 8), @alignOf(HostApi));
    try std.testing.expectEqual(@as(usize, 8), @alignOf(ModuleApi));
}

test "compatibility requires matching version and sufficient size" {
    var host_api: HostApi = undefined;
    host_api.abi_version = abi_version;
    host_api.struct_size = @sizeOf(HostApi);
    try std.testing.expect(hostCompatible(&host_api));

    host_api.abi_version += 1;
    try std.testing.expect(!hostCompatible(&host_api));
}
