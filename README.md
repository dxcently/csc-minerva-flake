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
| `modules/aggregations/server/` | the `server` group: a Proxmox guest |
| `modules/nucleus/` | key-only SSH, firewall, flakes |
| `hosts/example-edge/` | a template host record (RFC 5737 / `example.org` placeholders) |
| `users/admin.nix` | the one account; no password, no keys |

## Use

```sh
nix eval --json .#inventory.example-edge     # what the host resolved
nix eval .#nixosConfigurations.example-edge.config.system.build.toplevel.drvPath
```

To run it, create a private flake that takes this one as an input, copy
`hosts/example-edge/default.nix` into it, and fill in your values there:

```nix
inputs.minerva.url = "github:dxcently/csc-minerva-flake";
```

## Secrets

None are stored here. The Cloudflare token lives in a file on the machine
(`minerva.edge.cloudflareTokenFile`, outside the Nix store) and reaches Caddy as
a systemd credential. Scope it to the one zone: Zone:DNS:Edit and Zone:Zone:Read.
Tailscale enrolls interactively; there is no auth key in the tree.

## Design rules

- One subdomain per app, each its own browser origin; never apps under paths.
- Advertise the narrowest route that does the job.
- The rebuild is the operator's call; nothing here switches a machine.

## Licence

MIT. See `LICENSE`.
