# Pixel SDK

`pixel-sdk` defines the stable C ABI between Pixel hosts and dynamically loaded
modules. It also contains small reusable native helpers whose correctness is
shared across consumers. It intentionally contains no host implementation,
graphics headers, or module framework.

Consumers declare the repository as a Zig dependency and import
`pixel_sdk.module("module_abi")`. During local development, use Zig 0.16's
project override:

```bash
zig build --fork=../pixel-sdk
```

The ABI exposes one cold-path discovery symbol, `pixel_module_query`, plus four
lifecycle callbacks:

- `update` runs on a host-owned worker independently of rendering.
- `prepare_render` latches immutable state once for a rendered frame.
- `render_view` records each host-provided view sequentially.
- `shutdown` quiesces module activity before resources are destroyed or code is
  unloaded.

Every callback is mandatory. Modules provide a no-op implementation when a
phase needs no work, allowing hosts to call the ABI directly without capability
checks. During pre-release development, compatibility requires an exact ABI
version and exact host/module table size.

Modules must synchronize state shared by `update` and rendering. The exported
single-producer, single-consumer `snapshot_exchange` helper provides a
latest-value triple buffer for that boundary. The `time` helper contains the
shared monotonic-clock and sleep operations used by native consumers.

Run the ABI layout and compatibility tests with:

```bash
zig build test
```

## Releases

`v0.1.0` keeps ABI version `1` and adds the host-owned websocket service to
`HostApi`.

The `v0.2.0` release keeps ABI version `1` and adds host-owned PCM16 capture and
playback. Audio clients request an exact sample rate and channel count, poll
captured bytes, submit playback bytes, and can clear queued playback for
realtime interruption.

Current `v0.3.0` development keeps ABI version `1`, preserves all existing
field offsets, and appends `shutdown` and `prepare_render` to `ModuleApi`.
`update` now receives an independent monotonic tick through `UpdateInfo`. All
host services and module callbacks in the current table are mandatory.
