# sketchup-claude-bridge

Run Ruby inside a **running SketchUp** from the terminal. It was built so an AI coding agent
(Claude Code) can drive SketchUp. The agent writes geometry with the Ruby API, then measures the
model and exports views to check its own work.

It's about 50 lines of Ruby plus a small shell client, with no gems, sockets or ports.

## How it works

```
terminal ──writes──▶ ~/.sketchup-bridge/cmd.rb ──▶ SketchUp timer (0.5 s) evals it
terminal ◀──reads─── ~/.sketchup-bridge/out.txt ◀── "OK: <result>" or "ERROR: … backtrace"
```

## Setup

1. Start SketchUp with the bridge as a startup script (macOS):

   ```bash
   open -a "SketchUp 2026" model.skp --args -RubyStartup /path/to/claude_bridge.rb
   ```

   Pass a `.skp` file: if SketchUp opens to the Welcome screen, the startup script runs only
   after a model is opened. You can also run `load '/path/to/claude_bridge.rb'` in
   *Extensions → Developer → Ruby Console*.

2. Send code:

   ```bash
   ./skrun 'Sketchup.active_model.entities.size'
   ./skrun "$(cat build.rb)" 900     # timeout in seconds, default 600
   ```

   `skrun` exits with `0` = OK, `1` = Ruby error, `2` = no answer (bridge not running).

Set `SKETCHUP_BRIDGE_DIR` in both SketchUp's environment and your shell to change the folder.
The default is `~/.sketchup-bridge`.

## Example: build, then verify

```bash
./skrun '
m = Sketchup.active_model
g = m.entities.add_group
f = g.entities.add_face([0,0,0], [5000.mm,0,0], [5000.mm,3000.mm,0], [0,3000.mm,0])
f.reverse! if f.normal.z < 0
f.pushpull(2700.mm)
m.active_view.zoom_extents
m.active_view.write_image(filename: File.expand_path("~/box.png"), width: 1600, height: 1000)
b = g.bounds; [b.width.to_mm, b.height.to_mm, b.depth.to_mm]'
# OK: [5000.0, 3000.0, 2700.0]
```

## Security

Anything written to `cmd.rb` runs with SketchUp's permissions. The folder is created with mode `700`.
The bridge stays active only while SketchUp runs. It is not installed as a plugin, so a normal
SketchUp launch does not load it. You can stop it at any time with `ClaudeBridge.stop`.

Tested on SketchUp 2026 (26.1, Ruby 3.2) on macOS.
