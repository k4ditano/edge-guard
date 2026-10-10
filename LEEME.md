# Edge guard

Una batalla pequeña que vive en el borde de abajo de tu monitor, por encima de
lo que tengas abierto. Está hecha con
[pleamar](https://github.com/k4ditano/pleamar).

> **Obra de fan inspirada en Minecraft.** No es un producto oficial de
> Minecraft, ni está aprobada por Mojang o Microsoft ni asociada a ellos.
> Los detalles, en el apartado «Rights» de [README.md](README.md).

## Qué necesita

- Linux con un compositor Wayland que tenga layer-shell: Hyprland, Sway, niri,
  KDE Plasma, pleamar-wm. En GNOME no funciona.
- **pleamar 0.3.0 o posterior.** Se instala en tu carpeta personal con:

  ```sh
  curl -fsSL https://raw.githubusercontent.com/k4ditano/pleamar/main/install.sh | sh
  ```

- PipeWire o PulseAudio para el sonido.

Solo se ha probado en un ordenador (pleamar-wm, tarjeta NVIDIA, monitor 1080p).

## Jugar

```sh
./play.sh            # en el monitor que elija tu compositor
./play.sh DP-1       # en ese monitor
./play.sh stop       # lo cierra
```

La primera vez copia la fuente del juego (Monocraft) a `~/.local/share/fonts`.

- **Héroes:** arrastra uno a donde quieras que se ponga.
- **El cofre o la mesa del campamento:** abre la mesa de crafteo. Las cosas se
  llevan con el ratón; el botón derecho coge la mitad de un montón o deja una.
- **El libro**, a la izquierda de la mesa, sabe las recetas de lo que ya has
  encontrado y las coloca al pulsarlas.
- **La barra de nueve:** pulsa una cosa para usarla (TNT, poción, telaraña) y
  luego pulsa dónde.
- **Los cofres** que quedan tras una oleada esperan a que los pulses.
- **Cada cinco oleadas** cambia la zona, y es adonde vuelves si cae el
  campamento. Un héroe caído sigue caído hasta que la oleada se gana o se pierde.
- **Dos botones pequeños:** pausa, y guardarlo en una esquina.

La partida se guarda en `~/.local/share/pleamar/guard/guard4.json`.
