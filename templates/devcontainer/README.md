# Dev container (optional)

Installed into an adopter repository as `.devcontainer/` by `@flutter-scaffold devcontainer`.

**What it gives you:** one pinned Flutter toolchain for every developer, agent and CI job, so a check that passes in one place passes everywhere. It also removes the most common cause of `unverified` results: an agent on a machine with no Flutter SDK.

**What it cannot do:** iOS and macOS builds (they need a Mac with Xcode). Android emulators inside Docker are slow; prefer a physical device or a host emulator.

| Use | Command |
|-----|---------|
| VS Code / Cursor | "Reopen in Container" |
| Any CLI agent, one-off | `docker build -t app-dev .devcontainer && docker run --rm -it -v "$PWD":/work -w /work app-dev bash` |
| Run the local gate | inside the container: the commands from `DOCS_FLUTTER_STACK.md` |

**Pin it.** Replace `:stable` in the `Dockerfile` with the exact image tag matching the SDK pin in `DOCS_FLUTTER_STACK.md`. A floating tag means two developers can get different analyzers on the same day.

**Agents in containers:** a container limits what a misbehaving agent can reach, but a mounted repository is still writable. Commit before an unattended run.
