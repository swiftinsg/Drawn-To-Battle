# Home screen Rive background

`scene.rml` is the editable source for `Drawn To Battle/HomeBackground.riv`.
It is a 15-second looping ambient scene: drifting gold/blue/purple glows,
two slowly rotating orbit rings, four planets that hug those ellipses on smooth
cubic arcs while spinning on their axes, and a twinkling star field. The orbits
span the full landscape artboard so every planet stays on screen under the home UI.

Your Rive CLI is at `~/.rive/bin/rive`. Useful commands from the repo root:

```bash
export PATH="$HOME/.rive/bin:$PATH"
rive RiveSource/HomeBackground --verify                       # compile check
rive RiveSource/HomeBackground --screenshot=preview.png       # still frame
```

`--publish` needs a Rive account. To export a signed-free `.riv` locally, use
the already-cached 1.0.3 CLI, which writes an unsigned file on any build:

```bash
~/.rive/versions/1.0.3/rive RiveSource/HomeBackground --screenshot=preview.png
cp RiveSource/HomeBackground/build/HomeBackground.riv "Drawn To Battle/HomeBackground.riv"
```

The app loads it with `File(source: .local("HomeBackground", Bundle.main))`
in `Views/RiveHomeBackground.swift`, which sits behind the fighter on the
home screen over the hub's dark base colour (there is no static backdrop).
