# Agent Guide

This repository contains Lua scripts for CC: Tweaked computers and turtles. Treat it as a ComputerCraft project, not a general Lua app: code runs inside the in-game Lua environment and depends on APIs such as `turtle`, `fs`, `http`, `rednet`, `peripheral`, `parallel`, `shell`, `textutils`, `colours`, and `os`.

## Project Layout

- `bootstrap.lua` downloads files from GitHub onto an in-game computer by role.
- `local-bootstrap.sh` symlinks this checkout into a local Minecraft save for development.
- `manager/` is the central computer role. It owns dispatching, settings, turtle state, and monitor UI startup.
- `quarry/` is the quarry turtle role.
- `runner/` is the helper turtle role for general work.
- `wireless/` contains the shared message protocols, router, discovery, and service APIs.
- `movement/` contains shared turtle movement, locating, fuel, and state helpers.
- `display/` contains monitor UI pages and elements for the manager.
- `lib/` contains shared utilities.

Role deployment is intentionally selective:

- Manager gets `manager/` at computer root plus `lib/`, `wireless/`, and `display/`.
- Quarry gets `quarry/` at computer root plus `lib/`, `wireless/`, and `movement/`.
- Runner gets `runner/` at computer root plus `lib/`, `wireless/`, and `movement/`.

Keep this layout in mind when adding `require(...)` calls. Code under a role directory is copied to the computer root, so role-local modules are required without the role prefix, for example `require("settings")` from `manager/startup.lua`. Shared modules keep their folder prefix, for example `require("lib.printer")` or `require("wireless")`.

## Development Workflow

There is no package manager, lockfile, or automated test suite in this repository.

For local in-game testing:

```sh
./local-bootstrap.sh --set-save <SAVE_DIR>
./local-bootstrap.sh manager <COMPUTER_ID>
./local-bootstrap.sh quarry <COMPUTER_ID>
./local-bootstrap.sh runner <COMPUTER_ID>
```

For remote bootstrap testing, use the README flow:

```sh
wget https://raw.githubusercontent.com/rahmerh/turtle-manager/refs/heads/main/bootstrap.lua
bootstrap manager
bootstrap quarry
bootstrap runner
```

When changing deployment layout, update both `bootstrap.lua` and `local-bootstrap.sh` so GitHub bootstrap and local symlink bootstrap stay equivalent.

## Coding Conventions

- Use Lua modules that return a table or constructor table.
- Prefer `local` for module imports, helper functions, and state.
- Follow existing naming: files use snake case or kebab case where already established; variables and functions generally use snake case.
- Keep ComputerCraft spelling/API compatibility, including `colours`, `textutils`, `fs`, and `parallel.waitForAny`.
- Preserve the existing error-return style where functions return `nil/false, err` instead of throwing, unless the surrounding module already throws for invalid programmer input.
- Validate public constructor/input parameters with `lib.validator` when matching nearby display or utility code.
- Avoid adding dependencies that are not available in CC: Tweaked.

## Wireless Behavior

Wireless services are protocol-oriented. When adding operations:

- Define operation/protocol constants in the relevant `wireless/services/*.lua` module.
- Register manager-side handlers through `wireless.router.register_handler(protocol, operation, handler)`.
- Keep message payloads table-shaped and explicit; most callers expect `msg.data`.
- Be careful with operation names: `wireless/router.lua` indexes handlers by operation, with protocol checked after lookup.

## UI Behavior

The display code targets ComputerCraft monitors, so layout is character-cell based.

- Keep monitor size constraints in mind.
- Use existing elements in `display/elements/` before adding new primitives.
- Restore foreground/background colours after rendering, as existing elements do.
- Avoid text that can exceed fixed element widths unless you explicitly truncate, wrap, or validate it.
