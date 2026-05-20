# alfabeto.digital
## Conspiratorios populares de las soberanías

```
.
├── .gitattributes
├── .gitignore
├── .sops.yaml.template
├── LICENSE
├── README.md
├── nixos
│   ├── .config
│   │   └── awesome
│   │       ├── error_handling.lua
│   │       ├── functions.lua
│   │       ├── globals.lua
│   │       ├── keybindings.lua
│   │       ├── rc.lua
│   │       ├── rules.lua
│   │       ├── theme.lua
│   │       ├── wibar.lua
│   │       └── widgets/
│   ├── config.nix.template
│   ├── config-vps.nix.template
│   ├── flake.nix
│   ├── hardware-configuration-vps.nix
│   ├── home
│   │   └── default.nix
│   ├── modules
│   │   ├── hosts
│   │   │   ├── alfabeto.digital
│   │   │   │   └── default.nix
│   │   │   └── vps
│   │   │       └── default.nix
│   │   └── nixos
│   │       ├── admin.nix
│   │       ├── base.nix
│   │       ├── database.nix
│   │       ├── storage.nix
│   │       ├── communications
│   │       │   ├── dendrite.nix
│   │       │   ├── ntfy.nix
│   │       │   └── stalwart.nix
│   │       ├── network
│   │       │   ├── caddy.nix
│   │       │   ├── cloudflare.nix
│   │       │   ├── newt.nix
│   │       │   └── pangolin-server.nix
│   │       ├── security
│   │       │   ├── adguard.nix
│   │       │   └── authelia.nix
│   │       └── services
│   │           ├── syncthing.nix
│   │           └── vaultwarden.nix
│   ├── replicate-grub
│   │   └── ventoy/
│   └── secrets
│       ├── secrets.plain.template
│       └── secrets-vps.plain.template
└── vps
    ├── .gitignore
    ├── config
    │   ├── dynamic
    │   │   └── routes.toml
    │   ├── gerbil.yaml
    │   ├── pangolin.yaml
    │   └── traefik.toml
    ├── docker-compose.yml
    ├── secrets.env.template
    └── setup.sh
```

---

## Enabled services

| Service | Description |
|---|---|
| caddy | Reverse proxy and HTTPS with ACME/Let's Encrypt |
| vaultwarden | Bitwarden-compatible password manager |
| syncthing | File synchronization |
| postgresql | Database server |
| authelia | SSO / 2FA authentication portal |
| adguardhome | DNS server with ad blocking |
| stalwart-mail | Mail server (SMTP/IMAP) |
| dendrite | Matrix homeserver |
| ntfy | Push notification server |
| cloudflare / newt | Zero Trust tunnel — configurable via `tunnel_type` in `config.nix` |
| pangolin | WireGuard tunnel manager (VPS) |
| gerbil | WireGuard interface manager (VPS) |
| traefik | Reverse proxy for tunnel traffic (VPS) |

---

## NixOS installation

### 0. Before you begin

This guide assumes a server with two NVMe disks:

- `nvme0` — OS disk (NixOS), encrypted with LUKS during the installer
- `nvme1` — data disk (PostgreSQL), encrypted with LUKS manually before the first build

The external storage disk (`storage_name`) is not encrypted at this stage.

---

### 1. Install NixOS on nvme0

Boot from the ISO and install NixOS normally. During installation, enable LUKS on `nvme0` when the installer prompts for it. Once complete, the installer generates `hardware-configuration.nix` automatically with the LUKS configuration for the OS disk.

---

### 2. Encrypt nvme1 (data disk)

**a) Format with LUKS and create the filesystem:**

```bash
cryptsetup luksFormat /dev/nvme1n1    # choose an emergency passphrase
cryptsetup luksOpen /dev/nvme1n1 data-disk
mkfs.ext4 /dev/mapper/data-disk
cryptsetup luksClose data-disk
```

**b) Get the UUID and note it down:**

```bash
blkid /dev/nvme1n1
```

Set it in `config.nix`:

```nix
data_disk_uuid = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx";
```

> Enrolling the automatic unlock key is completed in step 5, after generating the secrets.

---

### 3. Generate the initrd SSH host key

The initrd SSH session allows remote LUKS unlocking of nvme0 after a reboot, without needing a monitor or keyboard.

```bash
mkdir -p /etc/secrets/initrd
ssh-keygen -t ed25519 -N "" -f /etc/secrets/initrd/ssh_host_ed25519_key
```

Copy the public key of the authorized machine to the initrd authorized keys file:

```bash
echo "ssh-ed25519 AAAA... user@host" > /etc/secrets/initrd/authorized_keys
chmod 600 /etc/secrets/initrd/authorized_keys
```

To unlock the server after a reboot:

```bash
ssh -p 2222 root@<server-ip>
# type the nvme0 passphrase at the prompt
```

---

### 4. Copy `config.nix.template` and fill values

`nixos/config.nix` is gitignored — it lives on the server only. Copy the committed
template and fill in all values before the first build:

```bash
cp nixos/config.nix.template nixos/config.nix
$EDITOR nixos/config.nix
```

Key fields to fill:

```nix
{
  # NixOS versions
  nixos_channel_version = "25.11";   # channel version used in flake inputs
  nixos_state_version   = "25.11";   # installation version — NEVER change after first build

  # System
  hostname = "";        # system hostname
  timezone = "";        # e.g. "America/New_York"

  # Locale
  locale_lang  = "";    # e.g. "en_US.UTF-8"
  locale_time  = "";    # e.g. "en_US.UTF-8"
  # ... (see config.nix.template for all locale fields)

  # Keyboard
  keyboard_console = "";   # console keymap (loadkeys)
  keyboard_x11     = "";   # X11 keymap     (localectl set-x11-keymap)

  # Users
  admin_username     = "";   # primary admin user
  admin_ssh_key      = "";   # contents of ~/.ssh/id_ed25519.pub
  syncthing_username = "";
  ftp_username       = "";

  # Database
  db_name          = "";   # PostgreSQL database name
  db_username      = "";   # PostgreSQL user
  data_mount_point = "/mnt/data";
  data_disk_uuid   = "";   # <-- fill with the nvme1 UUID from step 2

  # External storage
  storage_mount_point = "/mnt/storage";
  storage_name        = "";   # disk label / directory name
  storage_uuid        = "";   # fill from: blkid /dev/<device>

  # Domain & ACME
  domain     = "";   # primary domain
  email_acme = "";   # contact email for Let's Encrypt

  # Service ports (defaults are set in the template)
  # tunnel type: "cloudflare" or "newt"
  tunnel_type = "cloudflare";
}
```

> `nixos_state_version` reflects the NixOS version at the time of the initial installation. It must never be modified after the first build, regardless of subsequent system updates. `nixos_channel_version` is the only version field that changes when upgrading the system.

---

### 5. Set up SSH deploy key, age key, and secrets

> **Privacy strategy** — `config.nix`, all `secrets.*` filled/encrypted files, and
> `.sops.yaml` are listed in `.gitignore`. Only `*.template` files (with empty placeholder
> values) are committed. All sensitive work happens on the server itself.

**a) Enter a nix-shell with the required tools:**

```bash
nix-shell -p age sops
```

**b) Generate the age key for this host (first deploy only):**

```bash
mkdir -p /root/.config/sops/age
age-keygen -o /root/.config/sops/age/keys.txt
age-keygen -y /root/.config/sops/age/keys.txt   # outputs the public key — copy it
```

Take the public key (starts with `age1...`) and create `.sops.yaml` from the selfhosted server template:

```bash
cp .sops.yaml.template .sops.yaml
```

Fill in the public key:

```yaml
creation_rules:
  - path_regex: nixos/secrets/secrets\.yaml$
    age: "age1..."   # paste public key here
```

Delete the templates that are not needed on this machine:

```bash
rm .sops-vps.yaml.template
rm nixos/secrets/secrets-vps.plain.template
```

`.sops.yaml` is gitignored and stays on the server only.

**c) Copy the template and fill in values:**

```bash
cp nixos/secrets/secrets.plain.template nixos/secrets/secrets.plain
$EDITOR nixos/secrets/secrets.plain
```

Generation commands for each value are documented inside the template file.

**d) Encrypt and delete the plain file:**

```bash
sops --encrypt nixos/secrets/secrets.plain > nixos/secrets/secrets.yaml
rm nixos/secrets/secrets.plain
```

(With `.sops.yaml` configured, `sops --encrypt` picks the age key automatically.)

**e) Enroll `luks_data_key` in the nvme1 LUKS header:**

This allows the system to unlock nvme1 automatically at every boot using the sops-managed key, while keeping the emergency passphrase from step 2 as a backup in a separate key slot.

```bash
LUKS_KEY=$(sops --decrypt --extract '["luks_data_key"]' nixos/secrets/secrets.yaml)
echo "$LUKS_KEY" | cryptsetup luksAddKey /dev/nvme1n1
# enter the emergency passphrase from step 2 when prompted
unset LUKS_KEY
```

Verify that both key slots are registered:

```bash
cryptsetup luksDump /dev/nvme1n1 | grep "Key Slot"
```

---

### 6. Clone the repository and build the system

Install git if not already available:

```bash
nix-shell -p git
```

Save the `hardware-configuration.nix` generated by the installer before replacing `/etc/nixos`:

```bash
cp /etc/nixos/hardware-configuration.nix /tmp/hardware-configuration.nix
```

Clone the repository and symlink the `nixos/` directory into place:

```bash
git clone git@github.com:<your-org>/<your-repo>.git ~/alfabeto.digital
ln -sf ~/alfabeto.digital/nixos /etc/nixos
```

Restore the machine-specific hardware configuration:

```bash
cp /tmp/hardware-configuration.nix /etc/nixos/hardware-configuration.nix
```

> `hardware-configuration.nix` is machine-specific and generated by the installer. It is intentionally not tracked in the repository. Always restore it after cloning.

Build the system for the first time:

```bash
cd /etc/nixos
nixos-rebuild switch --flake .#$(nix eval --raw 'import ./config.nix'.hostname)
```

---

## NixOS version management

All hosts share one pinned nixpkgs defined in `flake.nix` and locked in `flake.lock`.
`nixos_channel_version` in `config.nix` is informational only — it does not drive the
nixpkgs URL. `nixos_state_version` reflects the NixOS version at initial installation
and must never be changed after the first build; it can differ between hosts installed
at different times.

To upgrade nixpkgs across all hosts: edit the channel URL in `flake.nix`, then run
`nix flake update`. Both hosts rebuild against the new pinned revision.

---

## Updates

Two shell aliases are defined in `home/default.nix`:

```bash
rebuild-nixos   # build only — no activation (use to check for errors first)
switch-nixos    # build + activate
```

Or manually:

```bash
sudo nixos-rebuild build  --flake /etc/nixos#$(hostname)   # dry run
sudo nixos-rebuild switch --flake /etc/nixos#$(hostname)   # activate
```

To pull the latest configuration from the repository before rebuilding:

```bash
cd ~/alfabeto.digital
git pull
switch-nixos
```

---

---

## VPS (Pangolin server) deployment

The VPS runs the Pangolin / Gerbil / Traefik stack. Two deployment paths are available —
choose based on the VPS operating system:

| | Path A — NixOS (recommended) | Path B — Docker / Podman |
|---|---|---|
| OS requirement | NixOS | Any Linux with Docker or Podman |
| Config | `config-vps.nix` (gitignored) | `vps/config/*.yaml` (edit directly) |
| Secrets | sops-encrypted, own age key | `vps/secrets.env` (gitignored) |
| Deploy | `nixos-rebuild switch` | `docker compose up -d` |
| Files needed | Full repo clone | Only `vps/` directory |

---

### Path A — NixOS deployment

The VPS uses its **own age key**, completely separate from the selfhosted server, so a VPS
compromise cannot decrypt the main machine's secrets.

### Before the first deploy

**1. Copy `nixos/config-vps.nix.template` and fill values:**

```bash
cp nixos/config-vps.nix.template nixos/config-vps.nix
$EDITOR nixos/config-vps.nix
```

Key fields:
```nix
hostname  = "";              # VPS hostname
domain    = "";              # same domain as selfhosted server
vps_ip    = "FILL_VPS_IP";  # public IP of the VPS
container_runtime = "flake"; # or "podman" / "docker"
```

**2. Get or generate a NixOS installer on the VPS.**

If the VPS already runs any Linux distro, use [nixos-anywhere](https://github.com/nix-community/nixos-anywhere):

```bash
# From your local machine (needs nix + ssh access to root@<VPS_IP>)
nix run github:nix-community/nixos-anywhere -- \
  --flake .#vps root@<VPS_IP>
```

If the VPS already runs NixOS, skip to step 3.

**3. On the VPS, generate its age key:**

```bash
nix-shell -p age sops
mkdir -p /root/.config/sops/age
age-keygen -o /root/.config/sops/age/keys.txt
age-keygen -y /root/.config/sops/age/keys.txt   # copy the public key
```

Create `.sops.yaml` from the VPS template and fill in the VPS public key:

```bash
cp .sops-vps.yaml.template .sops.yaml
```

```yaml
creation_rules:
  - path_regex: nixos/secrets/secrets-vps\.yaml$
    age: "age1..."   # paste VPS public key here
```

Delete the templates that are not needed on the VPS:

```bash
rm .sops.yaml.template
rm nixos/secrets/secrets.plain.template
```

`.sops.yaml` is gitignored and stays on the VPS only.

**4. On the VPS, fill and encrypt the VPS secrets:**

```bash
# Pull the latest repo commit (with the updated .sops.yaml)
cd ~/alfabeto.digital && git pull

cp nixos/secrets/secrets-vps.plain.template nixos/secrets/secrets-vps.plain
$EDITOR nixos/secrets/secrets-vps.plain     # fill passwords and gerbil_pangolin_token

sops --encrypt nixos/secrets/secrets-vps.plain > nixos/secrets/secrets-vps.yaml
rm nixos/secrets/secrets-vps.plain
```

**5. Build and activate:**

```bash
nixos-rebuild switch --flake /root/alfabeto.digital/nixos#vps
```

Or from your local machine (cross-build + deploy):

```bash
nixos-rebuild switch --flake .#vps --target-host root@<VPS_IP>
```

**6. After the first Newt connection:**

Open the Pangolin admin panel → Sites → your site → Peers and note the WireGuard IP
assigned to the Newt client (`10.x.x.x`). Set it in `config-vps.nix`:

```nix
newt_peer_ip = "10.x.x.x";
```

Rebuild the VPS to activate the updated Traefik routes:

```bash
nixos-rebuild switch --flake /root/alfabeto.digital/nixos#vps
```

---

### Path B — Docker / Podman deployment (any Linux)

Use this path when the VPS already runs a non-NixOS Linux distribution (Ubuntu, Debian,
Fedora, etc.) and you just want to bring up the tunnel stack quickly without converting the
OS. It runs the exact same Traefik / Pangolin / Gerbil containers as Path A's container mode.

#### Get only the VPS files (sparse checkout)

If you only need the `vps/` directory and not the full NixOS configuration, use a sparse
checkout to avoid downloading the rest of the repository:

```bash
git clone --filter=blob:none --sparse git@github.com:<your-org>/<your-repo>.git alfabeto.digital-vps
cd alfabeto.digital-vps
git sparse-checkout set vps
```

This downloads only the `vps/` directory plus the root files (`.gitignore`, `README.md`).
You can update later with `git pull` inside `alfabeto.digital-vps/`.

Alternatively, if you already have a full clone, just `cd vps/`.

#### Configure

Edit the two config files with real values. The other files (`gerbil.yaml`, `traefik.toml`)
work as-is and do not need changes for a standard deployment.

**`vps/config/pangolin.yaml`**
```yaml
app:
  base_domain: "your-domain.com"   # apex domain for Pangolin subdomains

gerbil:
  base_endpoint: "1.2.3.4"         # public IP of this VPS
```

**`vps/config/dynamic/routes.toml`** — fill the domain and the WireGuard peer IP.
The WireGuard peer IP is only available after the first Newt connection (see step below).
Leave `FILL_AFTER_NEWT_CONNECTS` in place until then; update and restart once you have it.

```toml
[tcp.routers.selfhosted-server-https]
  rule = "HostSNIRegexp(`^(.+\\.)?your-domain\\.com$`)"
  ...

[tcp.services.pangolin-tunnel.loadBalancer]
  [[...servers]]
    address = "10.x.x.x:443"   # WireGuard peer IP assigned by Pangolin to the Newt client
```

#### Secrets

Config files live in the repo (with placeholder values). Secrets are kept in `vps/secrets.env`,
which is gitignored and never committed. There is no sops or age key needed for this path —
the secrets file is a plain key=value file that lives only on the VPS.

```bash
cd vps
cp secrets.env.template secrets.env
$EDITOR secrets.env
```

Fill in `GERBIL_PANGOLIN_TOKEN` (generate in the Pangolin admin panel: Settings → API Tokens).

#### Run with Docker

```bash
cd vps
docker compose up -d
```

To view logs:
```bash
docker compose logs -f
```

#### Run with Podman

```bash
cd vps
podman compose up -d      # podman >= 4.6 with built-in compose support
# or:
podman-compose up -d      # pip install podman-compose
```

> Podman runs rootless by default. For Gerbil to manage WireGuard interfaces it needs
> `NET_ADMIN` capability — run as root (`sudo podman compose up -d`) or configure
> `allow_host_net_binds` in `/etc/sysctl.conf`.

You can also use the included helper script which creates `secrets.env` automatically:
```bash
bash vps/setup.sh
docker compose -f vps/docker-compose.yml up -d
```

#### After the first Newt connection

Once the selfhosted server's Newt client connects, open the Pangolin admin panel → Sites → Peers
and note the WireGuard IP assigned to the Newt client (`10.x.x.x`). Update `routes.toml`:

```toml
address = "10.x.x.x:443"
address = "10.x.x.x:80"
```

Then restart Traefik to reload the config (it watches the directory, but a restart is safest):
```bash
docker compose restart traefik
```

#### Updating

```bash
cd alfabeto.digital-vps   # or wherever your clone is
git pull
cd vps
docker compose pull
docker compose up -d
```

---

## nixos/ file reference

| File | Description |
|---|---|
| `config.nix.template` | Selfhosted server config template — commit with empty values |
| `config-vps.nix.template` | VPS config template — commit with empty values |
| `config.nix` | Selfhosted server config — gitignored, lives on server only |
| `config-vps.nix` | VPS config — gitignored, lives on VPS only |
| `flake.nix` | Nix Flakes entrypoint |
| `hardware-configuration.nix` | Auto-generated by the installer — do not edit or commit |
| `home/default.nix` | User environment configuration (home-manager) |
| `secrets/secrets.plain.template` | Secrets template for selfhosted server — commit with empty values |
| `secrets/secrets-vps.plain.template` | Secrets template for VPS — commit with empty values |
| `secrets/secrets.yaml` | Encrypted secrets for selfhosted server — gitignored, lives on server only |
| `secrets/secrets-vps.yaml` | Encrypted secrets for VPS — gitignored, lives on VPS only |
| `.sops.yaml.template` | sops creation rules template — commit with placeholder keys |
| `replicate-grub/` | ISOs and custom Ventoy theme for the installation USB |