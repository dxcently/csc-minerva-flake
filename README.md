# Minerva Flake

The CSC public server flake: a minimal NixOS tree composed with
[habit](https://github.com/dxcently/habit), in the shape of dxflake. A host
selects capabilities from a registry and only what it selected is imported.

This repository is **public**. It holds capabilities and a placeholder example
host, never a real address, key, token or hostname. Real machines are host
records in a private overlay flake that consumes this one.

## What is here

| path | what |
|---|---|
| `modules/dendrites/tailscale.nix` | Tailscale node; optional subnet router (narrow `/32` routes) |
| `modules/dendrites/caddy-edge.nix` | Caddy with one wildcard cert by Cloudflare DNS-01; one subdomain per app |
| `modules/dendrites/proxmox-guest.nix` | QEMU guest agent, serial console, disk growth |
| `modules/dendrites/dev-tools.nix` | operator tools: neovim, tmux, ripgrep, jq, sops, age |
| `modules/aggregations/base/` | the `base` group every host selects: `proxmox-guest`, `dev-tools` |
| `modules/nucleus/` | key-only SSH, firewall, flakes, sops-nix secrets |
| `hosts/example-edge/` | a template host record (RFC 5737 / `example.org` placeholders) |
| `users/admin.nix` | the one account; no password, no keys |

## Use

```sh
nix build .#images.example-edge              # Proxmox VMA; restore with qmrestore
nix eval --json .#inventory.example-edge     # what the host resolved
nix eval .#nixosConfigurations.example-edge.config.system.build.toplevel.drvPath
```

To run it, create a private flake that takes this one as an input, copy
`hosts/example-edge/default.nix` into it, and fill in your values there:

```nix
inputs.minerva.url = "github:dxcently/csc-minerva-flake";
```

## Secrets (sops-nix)

Secrets are sops-nix: encrypted to the host's own SSH host key, decrypted to
`/run/secrets` at activation, never in the Nix store (`modules/nucleus/secrets.nix`).
`secrets/example-edge.yaml` holds dummy values encrypted to a discarded key, as a
shape reference only. Real secrets belong in your private overlay, not here. The
Cloudflare token reaches Caddy as a systemd credential. Scope it to the one zone: Zone:DNS:Edit and Zone:Zone:Read.
Tailscale enrolls interactively; there is no auth key in the tree.

## Design rules

- One subdomain per app, each its own browser origin; never apps under paths.
- Advertise the narrowest route that does the job.
- The rebuild is the operator's call; nothing here switches a machine.

## Licence

MIT. See `LICENSE`.
