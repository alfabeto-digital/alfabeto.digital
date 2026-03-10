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

## Servicios habilitados

| Servicio | Descripción |
|---|---|
| nginx | Servidor web y proxy reverso con Let's Encrypt (ACME) |
| vaultwarden | Gestor de contraseñas compatible con Bitwarden |
| syncthing | Sincronización de archivos |
| postgresql | Base de datos para quipu |
| cloudflared | Túnel Zero Trust de Cloudflare |

---

## Instalación de NixOS

### 0. Antes de empezar

Esta guía asume un servidor con dos discos NVMe:

- `nvme0` — disco del sistema operativo (NixOS), encriptado con LUKS durante el instalador
- `nvme1` — disco de datos (PostgreSQL), encriptado con LUKS manualmente antes del primer build

El disco externo de storage (`virgilio`) no se encripta en esta etapa.

---

### 1. Instalar NixOS en nvme0

Arrancar desde el ISO e instalar NixOS de forma normal. Durante la instalación, habilitar LUKS en `nvme0` cuando el instalador lo solicite. Al finalizar, el instalador genera `hardware-configuration.nix` automáticamente con la configuración de LUKS del disco del SO.

---

### 2. Encriptar nvme1 (disco de datos)

**a) Formatear con LUKS y crear el filesystem:**

```bash
cryptsetup luksFormat /dev/nvme1n1    # elegir una passphrase de emergencia
cryptsetup luksOpen /dev/nvme1n1 data-disk
mkfs.ext4 /dev/mapper/data-disk
cryptsetup luksClose data-disk
```

**b) Obtener el UUID y anotarlo:**

```bash
blkid /dev/nvme1n1
```

Copiar el UUID en `config.nix`:

```nix
data_disk_uuid = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx";
```

> El enrolamiento de la llave automática se completa en el paso 5, después de generar los secretos.

---

### 3. Generar la host key del initrd SSH

El initrd SSH permite desbloquear LUKS de nvme0 remotamente después de un reinicio, sin necesidad de monitor ni teclado.

```bash
mkdir -p /etc/secrets/initrd
ssh-keygen -t ed25519 -N "" -f /etc/secrets/initrd/ssh_host_ed25519_key
```

Copiar la llave pública del equipo autorizado al archivo de llaves del initrd:

```bash
echo "ssh-ed25519 AAAA... usuario@equipo" > /etc/secrets/initrd/authorized_keys
chmod 600 /etc/secrets/initrd/authorized_keys
```

Para desbloquear el servidor después de un reinicio:

```bash
ssh -p 2222 root@<ip-del-servidor>
# escribir la passphrase de nvme0 en el prompt
```

---

### 4. Configurar config.nix

Todos los parámetros del sistema viven en `nixos/config.nix`. Editar antes del primer build:

```nix
{
  # Versiones de NixOS
  nixos_channel_version = "25.11";   # versión del canal (flake inputs)
  nixos_state_version   = "25.11";   # versión de instalación — NO cambiar después

  # Sistema
  hostname = "alfabetodigital";
  timezone = "America/Bogota";

  # Locale
  locale_lang           = "en_US.UTF-8";
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

  # Teclado
  keyboard_console = "es";
  keyboard_x11     = "es";

  # Usuarios
  admin_username     = "coyote";
  syncthing_username = "syncthing";
  ftp_username       = "ftp";

  # Base de datos
  db_name          = "quipu";
  db_username      = "quipucamayoc";
  data_mount_point = "/mnt/data";
  data_disk_uuid   = "";   # <-- rellenar con el UUID de nvme1

  # Storage externo
  storage_mount_point = "/mnt/storage";
  storage_name        = "virgilio";
  storage_uuid        = "6b668f05-9700-4bdf-9924-341bac87eed6";

  # Dominio y ACME
  domain     = "alfabeto.digital";
  email_acme = "services@alfabeto.digital";

  # Puertos
  vaultwarden_port = 8222;
  syncthing_port   = 8384;
  ftp_port         = 21;
  initrd_ssh_port  = 2222;
}
```

> `nixos_state_version` refleja la versión de NixOS en el momento de la instalación inicial. No debe modificarse nunca después del primer build, independientemente de las actualizaciones del sistema.

---

### 5. Configurar secrets.plain y encriptar con sops

**a) Instalar las herramientas:**

```bash
nix-shell -p age sops
```

**b) Generar la llave age:**

```bash
mkdir -p /root/.config/sops/age
age-keygen -o /root/.config/sops/age/keys.txt
age-keygen -y /root/.config/sops/age/keys.txt   # copiar esta llave pública
```

**c) Rellenar `nixos/secrets/secrets.plain`:**

```yaml
# Contraseñas hasheadas — generar con: mkpasswd -m sha-512
root_password: ""
admin_password: ""

# Llave pública SSH del equipo autorizado
# Obtener con: cat ~/.ssh/id_ed25519.pub
# Copiar también a /etc/secrets/initrd/authorized_keys (paso 3)
admin_ssh_key: ""

# Contraseña de la base de datos (texto plano, sin hashear)
db_password: ""

# Token del túnel de Cloudflare Zero Trust (desde el dashboard)
cloudflare_token: ""

# Llave de encriptación para nvme1
# Generar con: python3 -c "import secrets; print(secrets.token_hex(32))"
luks_data_key: ""
```

**d) Encriptar y eliminar el archivo plano:**

```bash
cd /etc/nixos
sops --encrypt --age 'age1...' ./secrets/secrets.plain > ./secrets/secrets.yaml
rm ./secrets/secrets.plain
```

**e) Enrolar `luks_data_key` en el header de nvme1:**

Este paso permite que el sistema desbloquee nvme1 automáticamente en cada boot usando la llave de sops, manteniendo la passphrase de emergencia del paso 2 como respaldo.

```bash
LUKS_KEY=$(sops --decrypt --extract '["luks_data_key"]' ./secrets/secrets.yaml)
echo "$LUKS_KEY" | cryptsetup luksAddKey /dev/nvme1n1
# ingresar la passphrase de emergencia del paso 2 cuando se solicite
unset LUKS_KEY
```

Verificar que ambos key slots están registrados:

```bash
cryptsetup luksDump /dev/nvme1n1 | grep "Key Slot"
```

---

### 6. Copiar la configuración y construir el sistema

```bash
cp -r /ruta/al/repo/nixos /etc/nixos
cd /etc/nixos
nixos-rebuild switch --flake .#$(nix eval --raw 'import ./config.nix'.hostname)
```

---

## Actualizaciones

Desde el servidor, con el alias definido en `home/default.nix`:

```bash
update-nixos
```

O manualmente desde cualquier ubicación:

```bash
sudo nixos-rebuild switch --flake /etc/nixos#$(hostname)
```

---

## Estructura de nixos/

| Archivo | Descripción |
|---|---|
| `config.nix` | Variables centralizadas del sistema — el único archivo que se edita habitualmente |
| `configuration.nix` | Configuración declarativa completa del sistema |
| `flake.nix` | Entrypoint de Nix Flakes — lee la versión del canal desde `config.nix` |
| `hardware-configuration.nix` | Generado automáticamente por el instalador — no editar |
| `home/default.nix` | Configuración del entorno del usuario (home-manager) |
| `secrets/secrets.yaml` | Secretos encriptados con sops-nix y age |
| `secrets/secrets.plain` | Plantilla de secretos — eliminar después de encriptar |
| `00-hallucinations/` | Versiones anteriores de referencia — no se usan en producción |
| `replicate-grub/` | ISOs y tema personalizado de Ventoy para el USB de instalación |