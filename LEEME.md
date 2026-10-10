# Edge guard

Una batalla pequeña que vive en el borde de abajo de tu monitor, por encima de
lo que tengas abierto: un grupo defiende su campamento de las oleadas que
llegan por la derecha, a través de seis tierras con un señor al final de cada
una. El campamento mina, funde y cultiva trigo él solo, también con el juego
guardado o cerrado. Está hecha con
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

**El campo**

- **Héroes:** arrastra uno a donde quieras que se ponga.
- **Los cofres** que quedan tras una oleada esperan a que los pulses.
- **La barra de nueve:** pulsa una cosa para usarla. TNT, poción y telaraña
  piden después dónde; el pan, un collar, un pico, un corazón de hierro o una
  campana se usan al momento.
- **El rayo** es el botón pequeño con un rayo: cae sobre quien esté más cerca
  del campamento y tarda veinte segundos en volver.
- **Otros dos botones pequeños:** pausa, y guardarlo en una esquina.
- **Mando:** el stick izquierdo mueve al caballero, A lanza el rayo, Y lo silencia.

**Las tierras y sus señores**

- Hay seis tierras de cinco oleadas, cada una con sus criaturas y con cosas que
  se encuentran allí más que en ningún otro sitio. Si cae el campamento, el
  grupo vuelve a la primera oleada de la tierra en la que está; un héroe caído
  sigue caído hasta que la oleada se gana o se pierde.
- La quinta oleada trae al **señor** de esa tierra. Avisa de lo que va a hacer:
  una marca en el suelo y una barra que se llena bajo su nombre. El TNT o el
  rayo lo paran y lo dejan aturdido; una telaraña sobre la marca atrapa a los
  que saltan o aparecen detrás del grupo; el fuego del señor del Nether se
  esquiva arrastrando a los héroes fuera de las marcas. Con media vida, llama
  a los suyos.
- Cada señor deja un **trofeo**. Con ellos se hace lo mejor: un gólem y un
  clérigo que se unen al grupo, un tótem, el último arco y los dos últimos
  bastones.
- Al caer un señor se abre el camino a la tierra siguiente. **El mapa** (una
  página de la mesa) lleva al grupo a cualquier tierra abierta, y puede
  decirle que se quede en una, para reunir lo que da.
- El señor del End deja un Ojo. Con él, el mapa abre **un mundo nuevo**: las
  tierras y los niveles del grupo empiezan de cero, todo es más fuerte, y el
  grupo conserva lo que lleva y gana una estrella para siempre.

**El campamento**

- **El cofre o la mesa de crafteo** abren la mesa. Las cosas se llevan con el
  ratón; el botón derecho coge la mitad de un montón o deja una. **El libro**,
  a su izquierda, sabe las recetas de lo que ya has encontrado y las coloca al
  pulsarlas.
- **El panel** de la derecha es el grupo: arma, casco, peto, botas y amuleto
  cada uno. La experiencia llena niveles, en verde; el `+` de un héroe los
  gasta en ese héroe.
- **La mesa de encantamientos** los gasta en lo que llevan: pon un arma o una
  pieza de armadura, lapislázuli al lado, y elige una de las ofertas.
- **La mina** cava sola: púlsala para recoger lo que tenga. Un pico mejor
  encuentra más. **El horno** convierte hierro y oro en bruto en lingotes, con
  carbón o palos. **El trigo** crece solo: púlsalo cuando esté dorado.
- Los tres siguen con el juego guardado o cerrado (hasta ocho horas), y el
  grupo aguanta su tierra mientras tanto; al volver te cuenta lo que hicieron.
- `auto`, en la mesa, deja que el campamento lo haga todo solo: craftear,
  repartir, gastar los niveles en los héroes, alimentar el horno y recoger.
- Las otras páginas de la mesa son el **bestiario** (todo lo que has
  encontrado, cuántos han caído y qué dejaron) y los **logros**.

La partida se guarda en `~/.local/share/pleamar/guard/guard5.json`.
