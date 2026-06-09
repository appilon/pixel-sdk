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

## Releases

`v0.1.0` keeps ABI version `1` and appends the optional host-owned websocket
service to `HostApi`. Modules that use the service require a host with the full
`HostApi` size and non-null `websocket_open`, `websocket_close`,
`websocket_send`, and `websocket_poll` callbacks.
