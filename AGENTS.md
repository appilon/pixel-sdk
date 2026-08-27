# Agent Instructions

Read [`README.md`](README.md) before changing code. It is the shared human/agent
reference for the ABI, lifecycle, host services, helper semantics, consumption,
tests, and versioning. Keep descriptive contract documentation there; do not
duplicate it in this file.

## Scope

`pixel-sdk` owns only the stable native contract and small mechanics proven
useful across independent hosts or modules. Keep Android, OpenXR, host loaders,
render loops, model providers, application protocols, renderer kinds, visual
IDs, mesh/SDF formats, scene policy, and consumer capacity budgets out of it.

Change the ABI only for a genuinely shared host/module capability. Add a helper
only when it removes real duplication without importing consumer policy.

## ABI Rules

- Preserve explicit integer sizes, `extern struct` layouts, and `.c` calling
  conventions. Never expose Zig allocators, slices, errors, or implementation
  types.
- Treat `abi_version` independently from Git tags.
- Require exact ABI version and table-size matches while all consumers move in
  lockstep. Do not add unpublished compatibility branches.
- Keep every callback mandatory and non-null; unused phases use no-ops.
- Treat `update` as worker activity that may overlap rendering. Keep
  `prepare_render` and `render_view` bounded and allocation-free.
- Preserve normalized input validity bits and explicit left/right indexes. Do
  not leak OpenXR enums or host gesture/physics policy.
- Keep host service ownership explicit. Hosts clamp capacities and reject
  unsupported phases; modules must handle rejection.
- Keep `track_resource` bounded and load-phase-only. Temporary or replaceable
  resources remain module-owned.

`snapshot_exchange` stays a single-producer, single-consumer latest-value
exchange, not a general queue. `module_log` stays an allocation-free envelope,
not a generic metrics framework. Transport capacities remain consumer policy.

## Engineering

[TigerBeetle's TigerStyle](https://github.com/tigerbeetle/tigerbeetle/blob/main/docs/TIGER_STYLE.md)
sets the priority order: safety, performance, then developer experience.

- Prefer explicit control flow, fixed limits, minimal abstractions, and no
  recursion in runtime helpers.
- Assert invariants and test minimum, maximum, valid, invalid, layout, and
  compatibility boundaries.
- Use explicitly sized integers for ABI and persistent state.
- Keep functions under 70 lines and lines under 100 columns where practical.
- Follow Zig naming conventions and document ownership or intentional ABI
  constraints. Keep dependencies minimal and pinned.

Zig 0.16 is the source of truth, not older model memory. Inspect the pinned
compiler and bundled standard library when APIs are uncertain. Never use
`@cImport`; translate owned C headers with `addTranslateC`. Use explicit I/O,
allocator-explicit containers, explicit `root_module` build modules, and
extern/fixed-width ABI types.

## Workflow

Use the Docker workflow in the README. Run `make fmt` and `make test` before a
consumer pin changes. Every ABI edit requires layout and compatibility coverage
and a clear consumer migration.

Never commit generated output, caches, credentials, or machine-specific state.
Never commit or push without explicit instruction. Preserve unrelated dirty
work in every repository.
