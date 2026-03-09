# replicate
## Install grub2 theme

To install this theme on a USB drive with Ventoy 1.1.10, simply copy the `ventoy` folder to the Ventoy partition of the USB drive. The `ventoy` folder must contain:

Para instalar este tema en una USB con Ventoy 1.1.10, simplemente copia la carpeta `ventoy` a la partición Ventoy de la USB. La carpeta `ventoy` debe contener:

```md
ventoy/
    ├── ventoy.json
    ├── README.md
    └── theme/
        └── replicate/
            ├── background.png
            ├── ShureTechMonoNerdFont-Regular-32.pf2
            └── theme.txt
```

## How `ventoy.json` plugin system works (English)

In Ventoy, the `ventoy.json` file is the central configuration file used to enable and configure plugins. It must be placed inside the `/ventoy` directory at the root of the Ventoy partition. Through this JSON file, you can activate features such as themes, menu aliases, persistence, auto-install scripts, and more. For themes specifically, the `"theme"` section defines the path to the `theme.txt` file, the font files (`.pf2`), display mode (GUI), and graphics settings. Ventoy reads this configuration at boot time and applies the selected plugin settings automatically.

Ventoy documentation:
[https://www.ventoy.net/en/plugin_entry.html](https://www.ventoy.net/en/plugin_entry.html)

GRUB2 themes:
[https://www.gnome-look.org/browse?cat=109&ord=latestt](https://www.gnome-look.org/browse?cat=109&ord=latest)

---

## Cómo funciona el sistema de plugins `ventoy.json` (Español)

En Ventoy, el archivo `ventoy.json` es el archivo principal de configuración para habilitar y gestionar plugins. Debe ubicarse dentro del directorio `/ventoy` en la raíz de la partición Ventoy. A través de este archivo JSON se pueden activar funciones como temas, alias de menú, persistencia, scripts de auto-instalación, entre otras. En el caso de los temas, la sección `"theme"` define la ruta al archivo `theme.txt`, las fuentes (`.pf2`), el modo gráfico (GUI) y las opciones de video. Ventoy lee esta configuración al arrancar y aplica automáticamente los ajustes definidos.

Documentación de Ventoy:
[https://www.ventoy.net/en/plugin_entry.html](https://www.ventoy.net/en/plugin_entry.html)

Temas para GRUB2:
[https://www.gnome-look.org/browse?cat=109&ord=latestt](https://www.gnome-look.org/browse?cat=109&ord=latest)