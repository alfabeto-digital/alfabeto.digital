# alfabeto.digital
## Conspiratorios populares de las soberanías

```
.
├── LICENSE
├── README.md
├── nixos
│   ├── 00-hallucinations
│   │   ├── configuration-v.0.0.nix
│   │   └── configuration.nix
│   ├── config.nix
│   ├── configuration.nix
│   ├── flake.nix
│   ├── home
│   │   └── default.nix
│   ├── replicate-grub
│   │   ├── archlinux-2026.02.01-x86_64.iso
│   │   ├── nixos-graphical-25.11.6495.e764fc9a4058-x86_64-linux.iso
│   │   ├── nixos-minimal-25.11.6495.e764fc9a4058-x86_64-linux.iso
│   │   ├── replicate-grub.xcf
│   │   ├── replicate-logo.xcf
│   │   └── ventoy
│   │       ├── README.md
│   │       ├── theme
│   │       │   └── replicate
│   │       │       ├── ShureTechMonoNerdFont-Regular-32.pf2
│   │       │       ├── background.png
│   │       │       └── theme.txt
│   │       └── ventoy.json
│   └── secrets
│       └── secrets.plain
└── website
    ├── assets
    │   ├── css
    │   │   ├── about.css
    │   │   ├── header.css
    │   │   ├── landing.css
    │   │   ├── menu.css
    │   │   └── styles.css
    │   ├── fonts
    │   │   ├── Gohu
    │   │   ├── Monofur
    │   │   ├── OpenDyslexic
    │   │   └── ShareTechMono
    │   ├── images
    │   │   └── bg-texture.jpg
    │   ├── js
    │   │   ├── landing.js
    │   │   └── scripts.js
    │   └── library
    │       └── transdisciplinariedad-martin-barbero.pdf
    ├── components
    │   ├── about.html
    │   ├── header.html
    │   ├── landing.html
    │   └── menu.html
    ├── index.html
    └── pages
        ├── search.html
        ├── social.html
        ├── soon.html
        └── terminal.html
```

---

## Enabled services

| Service | Description |
|---|---|
| nginx | Web server and reverse proxy with Let's Encrypt (ACME) |
| vaultwarden | Bitwarden-compatible password manager |
| syncthing | File synchronization |
| postgresql | Database for quipu |
| cloudflared | Cloudflare Zero Trust tunnel |

---

## NixOS installation

### 0. Before you begin

This guide assumes a server with two NVMe disks:

- `nvme0` — OS disk (NixOS), encrypted with LUKS during the installer
- `nvme1` — data disk (PostgreSQL), encrypted with LUKS manually before the first build

The external storage disk (`virgilio`) is not encrypted at this stage.

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

### 4. Configure config.nix

All system parameters live in `nixos/config.nix`. Edit this file before the first build:

```nix
{
  # NixOS versions
  nixos_channel_version = "25.11";   # channel version used in flake inputs
  nixos_state_version   = "25.11";   # installation version — NEVER change after first build

  # System
  hostname = "alfabetodigital";
  timezone = "America/Bogota";

  # Locale — each LC category is independently configurable
  locale_lang           = "en_US.UTF-8";   # LANG and LC_MESSAGES
  locale_collate        = "C";
  locale_time           = "es_CO.UTF-8";
  locale_numeric        = "es_CO.UTF-8";
  locale_monetary       = "es_CO.UTF-8";
  locale_measurement    = "es_CO.UTF-8";
  locale_paper          = "es_CO.UTF-8";
  locale_address        = "es_CO.UTF-8";
  locale_telephone      = "es_CO.UTF-8";
  locale_name           = "es_CO.UTF-8";
  locale_identification = "es_CO.UTF-8";

  # Keyboard
  keyboard_console = "es";   # console keymap (loadkeys)
  keyboard_x11     = "es";   # X11 keymap     (localectl set-x11-keymap)

  # Users
  admin_username     = "coyote";
  syncthing_username = "syncthing";
  ftp_username       = "ftp";

  # Database
  db_name          = "quipu";
  db_username      = "quipucamayoc";
  data_mount_point = "/mnt/data";
  data_disk_uuid   = "";   # <-- fill with the nvme1 UUID from step 2

  # External storage
  storage_mount_point = "/mnt/storage";
  storage_name        = "virgilio";
  storage_uuid        = "6b668f05-9700-4bdf-9924-341bac87eed6";

  # Domain & ACME
  domain     = "alfabeto.digital";
  email_acme = "services@alfabeto.digital";

  # Service ports
  vaultwarden_port = 8222;
  syncthing_port   = 8384;
  ftp_port         = 21;
  initrd_ssh_port  = 2222;
}
```

> `nixos_state_version` reflects the NixOS version at the time of the initial installation. It must never be modified after the first build, regardless of subsequent system updates. `nixos_channel_version` is the only version field that changes when upgrading the system.

---

### 5. Configure secrets.plain and encrypt with sops

**a) Enter a nix-shell with the required tools:**

```bash
nix-shell -p age sops
```

**b) Generate the age key:**

```bash
mkdir -p /root/.config/sops/age
age-keygen -o /root/.config/sops/age/keys.txt
age-keygen -y /root/.config/sops/age/keys.txt   # copy this public key for the next step
```

**c) Fill in `nixos/secrets/secrets.plain`:**

```yaml
# Hashed passwords — generate with: mkpasswd -m sha-512
root_password: ""
admin_password: ""

# SSH public key of the authorized machine
# Get it with: cat ~/.ssh/id_ed25519.pub
# Also copy it to /etc/secrets/initrd/authorized_keys (step 3)
admin_ssh_key: ""

# Database password (plain text, not hashed)
db_password: ""

# Cloudflare Zero Trust tunnel token (from the dashboard)
cloudflare_token: ""

# Encryption key for nvme1 — generate with:
#   python3 -c "import secrets; print(secrets.token_hex(32))"
luks_data_key: ""
```

**d) Encrypt and delete the plain file:**

```bash
sops --encrypt --age 'age1...' ./secrets/secrets.plain > ./secrets/secrets.yaml
rm ./secrets/secrets.plain
```

**e) Enroll `luks_data_key` in the nvme1 LUKS header:**

This allows the system to unlock nvme1 automatically at every boot using the sops-managed key, while keeping the emergency passphrase from step 2 as a backup in a separate key slot.

```bash
LUKS_KEY=$(sops --decrypt --extract '["luks_data_key"]' ./secrets/secrets.yaml)
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
git clone https://github.com/your-org/alfabeto.digital.git ~/alfabeto.digital
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

## Updates

From the server, using the shell alias defined in `home/default.nix`:

```bash
update-nixos
```

Or manually:

```bash
sudo nixos-rebuild switch --flake /etc/nixos#$(hostname)
```

To pull the latest configuration from the repository before rebuilding:

```bash
cd ~/alfabeto.digital
git pull
update-nixos
```

---

## nixos/ file reference

| File | Description |
|---|---|
| `config.nix` | Central system variables — the only file that needs regular editing |
| `configuration.nix` | Full declarative system configuration |
| `flake.nix` | Nix Flakes entrypoint — reads the channel version from `config.nix` |
| `hardware-configuration.nix` | Auto-generated by the installer — do not edit or commit |
| `home/default.nix` | User environment configuration (home-manager) |
| `secrets/secrets.yaml` | Secrets encrypted with sops-nix and age |
| `secrets/secrets.plain` | Secrets template — delete after encrypting |
| `00-hallucinations/` | Earlier configuration drafts kept for reference — not used in production |
| `replicate-grub/` | ISOs and custom Ventoy theme for the installation USB |