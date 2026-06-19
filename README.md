# Pixel SDK

`pixel-sdk` defines the stable C ABI between Pixel hosts and dynamically loaded
modules. It also contains small reusable native helpers whose correctness is
shared across consumers. It intentionally contains no host implementation,
Android lifecycle, OpenXR loop, model provider logic, or module framework.

The current ABI version is `1`. The current Git release is `v0.4.0`. Those are
separate: Git tags describe SDK source releases, while `abi_version` describes
runtime binary compatibility.

Consumers declare the repository as a Zig dependency and import
`pixel_sdk.module("module_abi")`. During local development, use Zig 0.16's
project override:

```bash
zig build --fork=../pixel-sdk
```

## Current ABI

The ABI exposes one cold-path discovery symbol, `pixel_module_query`, host
services, and four mandatory module lifecycle callbacks:

- `update` runs on a host-owned worker independently of rendering.
- `prepare_render` latches immutable state once for a rendered frame.
- `render_view` records each host-provided view sequentially.
- `shutdown` quiesces module activity before resources are destroyed or code is
  unloaded.

Every callback is mandatory. Modules provide a no-op implementation when a
phase needs no work, allowing hosts to call the ABI directly without capability
checks. During pre-release development, compatibility requires an exact ABI
version and exact host/module table size.

Current host services cover bounded module allocation, structured logging,
tracked Vulkan resource teardown, websocket transport, PCM16 audio, JPEG
capture, and two-part websocket sends for prepended protocol bytes.

The ABI is C-compatible but currently Vulkan-oriented. Another Vulkan host can
consume it directly. A non-Vulkan host needs a deliberate future graphics
contract.

## Helpers

Modules must synchronize state shared by `update` and rendering. The exported
single-producer, single-consumer `snapshot_exchange` helper provides a
latest-value triple buffer for that boundary. The `time` helper contains the
shared monotonic-clock and sleep operations used by native consumers.
`module_log` emits allocation-free structured lifecycle events through the
host logger.

Run the ABI layout and compatibility tests with:

```bash
zig build test
```

## Versioning

Use SemVer tags for SDK source releases. Keep `abi_version` independent and
increment it only for runtime binary compatibility changes. While Pixel is
pre-public, consumers move in lockstep and require the complete current ABI.
