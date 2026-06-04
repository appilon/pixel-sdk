# Pixel SDK

`pixel-sdk` defines the stable C ABI between Pixel hosts and dynamically loaded
modules. It intentionally contains no host implementation, platform APIs,
graphics headers, or module framework.

Consumers declare the repository as a Zig dependency and import
`pixel_sdk.module("module_abi")`. During local development, use Zig 0.16's
project override:

```bash
zig build --fork=../pixel-sdk
```

The ABI exposes one cold-path discovery symbol, `pixel_module_query`, and two
frame-path callbacks: `update` and `render_view`.

Run the ABI layout and compatibility tests with:

```bash
zig build test
```
