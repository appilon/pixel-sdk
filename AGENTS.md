# Repository Guidelines

## Scope

`pixel-sdk` owns the stable, C-compatible contract shared by independent Pixel
hosts and modules, plus small reusable native helpers that enforce shared
concurrency or timing behavior. Keep the ABI platform-neutral and the helpers
free of host policy. Android, OpenXR, Vulkan headers, host loaders, render
loops, module examples, and build containers belong in consumer repositories.

## ABI Rules

- Preserve explicit integer sizes, `extern struct` layouts, and `.c` calling
  conventions.
- Treat `abi_version` as runtime binary compatibility, independent of Git tags.
- Until public distribution begins, update the SDK, host, and all modules in
  lockstep and require the complete current ABI.
- Require exact `abi_version` and `struct_size` matches. Do not add
  backward-compatibility branches for unpublished modules.
- Append fields when practical so layouts remain easy to audit.
- Never expose Zig allocators, slices, errors, or implementation-specific types.
- Keep every ABI callback mandatory and non-null. Consumers that need no work
  for a callback must provide a no-op implementation.
- Preserve the existing callback offsets and append lifecycle hooks at the end
  of `ModuleApi`.
- Treat `update` as worker-thread activity that may overlap
  `prepare_render`/`render_view`.
- Keep `prepare_render` and `render_view` bounded and allocation-free.
- Require `shutdown` before host resources are destroyed or module code is
  unloaded.
- Host services must preserve host ownership and reject unsupported phases.

`snapshot_exchange` is a single-producer, single-consumer latest-value triple
buffer. Do not broaden it into a general queue or multi-writer primitive.

`module_log` owns the allocation-free native module event envelope. Keep rich
domain telemetry in its owning host or module rather than growing a generic
metrics framework in the SDK.

## TigerStyle

[TigerBeetle's TigerStyle](https://github.com/tigerbeetle/tigerbeetle/blob/main/docs/TIGER_STYLE.md)
is the north star. Apply its priorities in order: safety, performance, then
developer experience. Design before implementation and fix discovered debt
before building on it.

Core rules:

- Prefer simple, explicit control flow, minimal excellent abstractions, and no
  recursion.
- Put fixed limits on queues, loops, resources, views, and work per frame.
- Assert invariants and handle every operational error. Test valid and invalid
  boundaries.
- Use explicitly sized integers in ABI and persistent state. Keep `usize` at
  unavoidable language or platform boundaries.
- Perform no dynamic allocation in the frame/render data path. Bounded
  allocation during startup, module load, or reload is control-plane work and
  must be explicit.
- Keep functions at most 70 lines and lines at most 100 columns. Run `zig fmt`
  and use four-space indentation.
- Use `snake_case` for files and variables, `camelCase` for functions, and
  `PascalCase` for types. Avoid abbreviations; suffix units and qualifiers,
  such as `frame_time_ns_max`.
- Explain why and how in complete-sentence comments. Keep dependencies and
  tooling minimal; prefer Zig for new repository tooling.

Document any deliberate TigerStyle deviation next to the decision and explain
why the ABI or native platform boundary requires it.

Pixel deliberately follows Zig's naming conventions instead of TigerStyle's
snake-case function names so native code remains idiomatic alongside the
standard library and generated platform bindings.

## Development

Target stable Zig 0.16.0.

Run `zig fmt build.zig src/` and `zig build test` before changing a pin in a
consumer. Every ABI change requires layout and compatibility tests plus a clear
migration note.
