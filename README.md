# Edge guard

A small idle battle that lives along the bottom edge of your monitor, over
whatever you have open. Three heroes hold a camp on the left; waves come from
the right. Clicks go through to your windows everywhere except on the game's
own pieces.

It is written in [pleamar](https://github.com/k4ditano/pleamar): one scene
(`guard.plm`) and its logic (`guard.luau`).

> **A fan work inspired by Minecraft.**
> NOT AN OFFICIAL MINECRAFT PRODUCT. NOT APPROVED BY OR ASSOCIATED WITH MOJANG
> OR MICROSOFT. See [Rights](#rights).

## What it needs

- Linux with a Wayland compositor that has layer-shell: Hyprland, Sway, niri,
  KDE Plasma, pleamar-wm. Not GNOME.
- **pleamar 0.3.0 or newer.** Its installer, in your home and nothing outside it:

  ```sh
  curl -fsSL https://raw.githubusercontent.com/k4ditano/pleamar/main/install.sh | sh
  ```

- PipeWire or PulseAudio, for its sounds.
- A game controller, if you want one. It is not needed.

It has been run on one machine so far (pleamar-wm, an NVIDIA card, a 1080p
monitor). Anywhere else it is untried.

## Play

```sh
./play.sh            # on the monitor your compositor picks
./play.sh DP-1       # on that one
./play.sh stop       # closes it
```

The first time, `play.sh` copies the game's font (Monocraft) into
`~/.local/share/fonts`.

- **Heroes:** drag one to where it should stand.
- **The camp's chest or table:** opens the crafting table. Things are carried
  with the mouse; the right button takes half of a pile, or puts down one. Lay
  them on the grid as the recipe says and take what they make from the slot at
  its right.
- **The book** at the table's left knows every recipe whose ingredients you
  have found, and lays one out when pressed.
- **The panel** at its right is what each hero carries.
- **The bar of nine:** press a thing to use it (TNT, a potion, a web), then
  press where it should go.
- **Chests** left on the field after a wave wait until you press them.
- **Every five waves** the land changes, and reaching one is where you come
  back to when the camp falls. A hero that falls stays down until the wave is
  won or lost.
- **Two small buttons** stop it where it is, or put it away into a corner.
- **A game controller:** the left stick moves the knight, A calls a lightning,
  Y silences it.

Your game is kept in `~/.local/share/pleamar/guard/guard4.json`.

## The pictures

Every picture in `pieces/` is made by the scripts in `art/`: the characters and
blocks are built box by box and rendered with Blender (`make.py`), packed into
sheets (`pack.py`), and the things are written out pixel by pixel
(`items.py`). `art/build.sh` makes them all again; it needs Blender and
Python's Pillow.

## Rights

- **No file of Mojang's is in here.** No texture, model, sound or font of
  Minecraft's was copied: the pictures come from the scripts in `art/`, and the
  sounds are tones made while it runs.
- **The characters, creatures and names are Mojang's all the same.** The
  creeper, the enderman, the Nether, the End and the rest belong to Mojang
  Studios and Microsoft, and what is drawn here imitates them on purpose. That
  makes this a fan work: to play and to share for free, **not to sell**, and
  not something this repository can give anyone a licence over.
- "Minecraft" is a trademark of Mojang Synergies AB. This project is not
  theirs, is not endorsed by them, and does not use their name as its own.
- **The font** is [Monocraft](https://github.com/IdreesInc/Monocraft) by Idrees
  Hassan, under the SIL Open Font License 1.1 (`fonts/OFL.txt`).
- **The code** (`guard.plm`, `guard.luau`, `art/`, `play.sh`) is Abel's. No
  licence has been chosen for it yet: ask before reusing it.
