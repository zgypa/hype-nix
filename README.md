# hype-nix

A reusable Nix package and flake for [Hype](https://github.com/omacom/hype),
the Markdown presentation editor.

The package pins Hype to a release tag and verifies its source hash in
`package.nix`. Even if the upstream tag moves, the fixed hash prevents its
contents from silently changing.
`flake.lock` pins nixpkgs. It includes the Qt/QML and Wayland plugins, the
desktop launcher, and runtime access to FFmpeg, ffprobe and GNU source-highlight.

It builds from source rather than using an Arch package. Omarchy, Nixarchy and
Hyprland are not build dependencies. Existing Omarchy themes can be discovered
at runtime; themes themselves are not bundled.

## Try locally

Requires Nix with the `nix-command` and `flakes` experimental features enabled.
On NixOS, add this to your configuration if needed and rebuild:

```nix
nix.settings.experimental-features = [ "nix-command" "flakes" ];
```

From this directory:

```bash
nix build
nix run . -- open
nix flake check
```

The build runs upstream's headless CLI tests against the installed executable,
including PNG rendering and PDF/PowerPoint export. `nix run .` without arguments
prints CLI help; use `open` to start the graphical editor.

## Install from GitHub

The flake fetches and builds Hype from its pinned upstream source.
This repository does not provide a binary cache.

Start the graphical editor without installing it:

```bash
nix run github:zgypa/hype-nix -- open
```

Or install it in a user profile:

```bash
nix profile install github:zgypa/hype-nix
hype open
```

## Add to a NixOS flake

Add this input to your existing `flake.nix`:

```nix
inputs.hype.url = "github:zgypa/hype-nix";
```

Pass your `inputs` into NixOS modules if your flake does not already do so:

```nix
# Inside nixpkgs.lib.nixosSystem { ... }
specialArgs = { inherit inputs; };
```

Then add the package in a NixOS module:

```nix
{ inputs, pkgs, ... }:
{
  environment.systemPackages = [
    inputs.hype.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
```

Rebuild your usual NixOS configuration. Hype's launcher is installed along with
the executable and should be available to your desktop's application menu.
Keep the portal services and fonts from your existing desktop configuration;
Hype's package does not configure system services.

## Home Manager instead

Pass `inputs` through Home Manager's `extraSpecialArgs` (standalone) or
`home-manager.extraSpecialArgs` (NixOS module), then add:

```nix
{ inputs, pkgs, ... }:
{
  home.packages = [
    inputs.hype.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
```

## Optional overlay

The flake also exports `overlays.default`, making `pkgs.hype` available:

```nix
{ inputs, pkgs, ... }:
{
  nixpkgs.overlays = [ inputs.hype.overlays.default ];
  environment.systemPackages = [ pkgs.hype ];
}
```

The overlay uses **your** nixpkgs and requires Qt 6.9 or newer. The direct
`inputs.hype.packages...` examples use this flake's pinned nixpkgs instead.
Avoid adding `inputs.hype.inputs.nixpkgs.follows = "nixpkgs"` unless your package
set has a sufficiently new Qt version.

For a configuration without flakes, copy `package.nix` into your configuration
repository and use `pkgs.qt6.callPackage ./package.nix { }` with a compatible
nixpkgs version.

## Themes

Upstream discovers themes under `$OMARCHY_PATH/themes`, defaulting to
`~/.local/share/omarchy/themes`, and also under `~/omarchy/themes` and
`~/.config/omarchy/themes`. If your installation stores them elsewhere, point
`OMARCHY_PATH` at the directory containing `themes`:

```bash
OMARCHY_PATH=/path/to/omarchy hype open
```

The package leaves that variable under your control.

## Update

The [Update Hype workflow](.github/workflows/update-hype.yml) uses
[`nix-update`](https://github.com/Mic92/nix-update) to check GitHub releases
daily (and can be run manually). If a newer stable release exists, it updates
the version and source hash in `package.nix`, builds and tests with
`nix flake check`, then commits and pushes to `main`.
There is no commit when the pinned version is already current. If a build or test
fails, the workflow stops without pushing; it will retry on the next run.
The workflow needs GitHub Actions write access to repository contents.

If you consume this flake through another flake's `flake.lock`, update that lock
file to pick up the new commit (for example, `nix flake update hype` in the
consumer repository) and rebuild your workstation. A GitHub push alone does not
change a consumer's locked inputs or install software on its machine.

To update dependencies while keeping Hype's source unchanged:

```bash
nix flake update nixpkgs
nix flake check
```

To update Hype manually, run:

```bash
nix run nixpkgs#nix-update -- hype --flake --use-github-releases
nix flake check
```

Verify the GUI on your desktop. Updates may require adjusting dependencies or tests.

## Validation status

Validated on 2026-09-29 with Nix 2.28.3:

- The source hash was verified with Nix's fetcher.
- `nix flake check --no-build --all-systems` passed for both exposed platforms.
- `nix build --dry-run` resolved the x86-64 build dependency closure successfully.
- The Qt qmake and application-wrapper hooks were inspected against the locked
  nixpkgs source.

**Compilation, execution of the bundled tests and GUI use have not been
verified.** The delivery environment supports Nix evaluation but lacks a usable
standard Nix store and disallows the namespaces needed to mount one temporarily.
Run `nix flake check` and `nix run . -- open` on your NixOS machine before treating
the package as build-tested. The test phase is included in the derivation; it has
not been run here.

The flake exposes `x86_64-linux` and `aarch64-linux`. An exposed platform is not
a claim that its build has been tested on real hardware.

## License

These packaging files use the MIT license. Hype's upstream source is also MIT;
the derivation installs upstream's license with the executable.
