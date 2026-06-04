# Repository Guidelines

## Scope

`pixel-sdk` owns only the stable, C-compatible contract shared by independent
Pixel hosts and modules. Keep this repository platform-neutral and
implementation-free. Android, OpenXR, Vulkan headers, host loaders, render
loops, module examples, and build containers belong in consumer repositories.

## ABI Rules

- Preserve explicit integer sizes, `extern struct` layouts, and `.c` calling
  conventions.
- Treat `abi_version` as runtime binary compatibility, independent of Git tags.
- Add fields only at the end of structs and gate access with `struct_size`.
- Never expose Zig allocators, slices, errors, or implementation-specific types.
- Keep frame callbacks limited to `update` and `render_view`.
- Host services must preserve host ownership and reject unsupported phases.

## Development

Target Zig 0.16.0 and follow
[TigerStyle](https://github.com/tigerbeetle/tigerbeetle/blob/main/docs/TIGER_STYLE.md):
safety first, then performance, then developer experience. Prefer fixed limits,
explicit invariants, simple control flow, and no frame-path allocation.

Run `zig fmt build.zig src/` and `zig build test` before changing a pin in a
consumer. Every ABI change requires layout and compatibility tests plus a clear
migration note.
