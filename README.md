# Neon Kitchen

Godot game project.

## Project documentation

Open the repository `docs/` directory as an Obsidian vault. Start at
[docs/Home.md](docs/Home.md).

The game design, architecture, ADRs, agent definitions, and durable Kitchen
Lead memory are versioned with the game. GitHub Issues and the
[Neon Kitchen Development Project](https://github.com/users/rkhanna24/projects/1)
track executable work.

## The content crew

Four Claude Code agents turn a plain-English design brief into validated `.tres`
game content, judged by the game's own validator, evaluator, and gate. See
[docs/crew/README.md](docs/crew/README.md) for the diagram, the roles, and how to
run it.

## Running and building

Play it:

```bash
godot --path .
```

Verify everything before committing:

```bash
./scripts/check.sh
```

Build a desktop binary:

```bash
mkdir -p build/macos build/windows
godot --headless --path . --export-release "macOS" build/macos/NeonKitchen.app
godot --headless --path . --export-release "Windows Desktop" build/windows/NeonKitchen.exe
```

The output directory must already exist — Godot reports `The given export path
doesn't exist` and fails rather than creating it.

Export needs Godot's **export templates**, a ~1GB download matched to the
engine version. They are not a declared project dependency. Install them from
the editor (Editor → Manage Export Templates) or directly:

```bash
DEST="$HOME/Library/Application Support/Godot/export_templates/4.7.1.stable"
mkdir -p "$DEST"
curl -sL -o /tmp/templates.tpz \
  https://github.com/godotengine/godot/releases/download/4.7.1-stable/Godot_v4.7.1-stable_export_templates.tpz
unzip -q -o -j /tmp/templates.tpz 'templates/*' -d "$DEST"
```

`./scripts/verify_export.sh` proves the build is sound without needing them —
it exports a pack, checks the whole content set and the compiled translation
are in it, checks nothing that should not ship is, and runs the exported build
to confirm content resolves through the `.tres.remap` indirection an export
introduces. `check.sh` runs it.
