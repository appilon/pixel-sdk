# Pixel SDK

`pixel-sdk` defines the stable C-compatible ABI between Pixel hosts and
dynamically loaded native modules. It also contains small native helpers whose
correctness is shared across consumers. It intentionally contains no Android
lifecycle, OpenXR loop, host loader, model provider, scene protocol, or module
framework.

Related repositories:

- `/home/alex/git/pixel-quest`: current Android/OpenXR/Vulkan host.
- `/home/alex/git/pixel-harness`: active AI-directed module and control plane.
- `/home/alex/git/pixel-module-demo`: minimal ABI consumer.

The current ABI version is `1`; the current source release is `v0.10.0`. These
are independent. Git tags version SDK source, while `abi_version` identifies
runtime binary compatibility.

## Module Contract

Modules export one cold-path discovery symbol, `pixel_module_query`, and return
four mandatory lifecycle callbacks:

- `update`: runs on a host-owned worker independently of rendering.
- `prepare_render`: latches immutable state once per rendered frame.
- `render_view`: records each host-provided view sequentially.
- `shutdown`: runs after updates stop and prior GPU submissions complete, but
  before tracked resources are destroyed or module code is unloaded.

Unused callbacks remain no-ops, allowing hosts to call the contract without
capability branches. During pre-public development, compatibility requires an
exact `abi_version` and exact host/module table size.

Each `update` receives a latest-value normalized two-hand snapshot. Explicit
left/right indexes and validity flags accompany palm pose, linear and angular
velocity, fingertip pinch position, and pinch strength. OpenXR joint enums,
Android input, gesture policy, and physics policy remain outside the ABI.

The lifecycle supports atomic renderer publication without naming renderer
techniques: `update` prepares a complete candidate, `prepare_render` latches it
at a frame-safe boundary, and every `render_view` consumes the same immutable
revision. Incomplete candidates leave the previous revision active.

## Host Services

The host table currently exposes bounded module allocation, structured logging,
tracked persistent Vulkan teardown, websocket transport, PCM16 audio, typed
capture sources, and two-part websocket sends for prepended protocol bytes.

Service handles remain host-owned and generation checked. Hosts define and
clamp capacities; modules handle capacity and queue rejection. Queue sizes,
capture dimensions, audio durations, and module arena sizes are consumer policy,
not ABI constants.

`track_resource` transfers bounded persistent resource cleanup to the host
during module load. It is not an unbounded retirement queue for live-created
resources. Temporary and replaceable resources remain module-owned; the host
must complete prior GPU work before `shutdown`.

The ABI is currently Vulkan-oriented despite being C-compatible. Another Vulkan
host can consume it directly. Metal, WebGPU, or software hosts require a
deliberate future graphics contract.

## Helpers

- `snapshot_exchange`: single-producer, single-consumer latest-value triple
  buffer for update/render handoff.
- `time`: shared monotonic clock and sleep operations.
- `module_log`: allocation-free structured module event envelopes through the
  host logger.

Helpers contain reusable mechanics, never host or product policy. Renderer
selection, model-authored artifacts, mesh/SDF formats, scene IDs, and the
Node-to-module protocol remain in `pixel-harness` until multiple independent
consumers prove a shared contract.

## Consume And Verify

Declare `pixel-sdk` as a pinned Zig dependency and import
`pixel_sdk.module("module_abi")`. Local sibling development uses Zig 0.16's
project override, which the consumer Makefiles mount as `/pixel-sdk`:

```bash
zig build --fork=../pixel-sdk
```

The SDK itself provides a pinned Zig 0.16 Docker workflow:

```bash
make fmt
make test
```

`make test` runs ABI layout/compatibility, snapshot concurrency, time, and
structured logging tests.

## Versioning

SDK source releases use SemVer. Increment `abi_version` only for runtime binary
compatibility changes. While Pixel remains pre-public, update the SDK, host, and
all modules in lockstep and require the complete current ABI.
