# Edge guard

A small idle battle that lives along the bottom edge of your monitor, over
whatever you have open. A party holds a camp on the left; waves come from the
right, through six lands, each with a lord at the end of it. The camp mines,
smelts and grows wheat by itself, also while the game is put away or closed.
Clicks go through to your windows everywhere except on the game's own pieces.

It is written in [pleamar](https://github.com/k4ditano/pleamar): one scene
(`guard.plm`) and its logic (`guard.luau` and the four parts in `logic/`).

> **A fan work inspired by Minecraft.**
> NOT AN OFFICIAL MINECRAFT PRODUCT. NOT APPROVED BY OR ASSOCIATED WITH MOJANG
> OR MICROSOFT. See [Rights](#rights).

## What it needs

- Linux with a Wayland compositor that has layer-shell: Hyprland, Sway, niri,
  KDE Plasma, pleamar-wm. Not GNOME.
- **pleamar 0.4.10 or newer.** Its installer, in your home and nothing outside it:

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

**The field**

- **Heroes:** drag one to where it should stand.
- **Chests** left on the field after a wave wait until you press them.
- **The bar of nine:** press a thing to use it. TNT, a potion or a web then
  want a press where they should go; bread, a collar, a pickaxe, a heart of
  iron or a bell are used at once.
- **The lightning** is the small button with a bolt: it strikes whoever is
  nearest the camp, and is ready again in twenty seconds.
- **Two more small buttons** stop the game where it is, or put it away into a
  corner.
- **A game controller:** the left stick moves the knight, A calls the
  lightning, Y silences it.

**The lands and their lords**

- There are six lands of five waves. Each has its own creatures, and things
  that are found there more than anywhere else. When the camp falls, the party
  goes back to the first wave of the land it is in; a hero that falls stays
  down until the wave is won or lost.
- The fifth wave brings the land's **lord**. A lord announces what it is about
  to do: a mark on the ground and a bar that fills under its name. TNT or the
  lightning stop it and leave it dazed; a cobweb thrown on the mark catches
  the ones that leap or step behind the party; the fire of the Nether's is
  dodged by dragging the heroes off the marks. With half of it gone, it calls
  its own.
- A lord leaves a **trophy**. The best things are made with them: a golem and
  a cleric to join the party, a totem, the last bow and the last two staffs.
- When a lord falls the way to the next land opens. **The map** (a page of the
  table) takes the party to any land whose way is open, and can tell it to
  stay in one, to gather what that land gives.
- The lord of the End leaves an Eye. With it, the map opens **a new world**:
  the lands and the party's levels start over, everything is stronger, and the
  party keeps what it carries and is a star stronger for good.

**The camp**

- **The chest or the crafting table** open the table: a pane of glass over
  your desktop, its pages as tabs above it. Things are carried as there:
  - a press picks up a pile, another puts it down, onto a pile of its kind or
    in place of what is there; the right button takes half, or puts down one;
  - **dragged over several slots**, a pile is shared out evenly among them
    (with the right button, one in each);
  - **twice on a slot**, everything of that kind comes into the hand;
  - **Shift** and a press sends a pile where it belongs: between what is kept
    and the bar, into the furnace or onto the enchanting table, onto the hero
    who can wear it, out of the grid; on what the grid makes, as many as there
    is for;
  - **1 to 9** swap the slot under the mouse with that slot of the bar, **Sort**
    puts piles of a kind together, and **Esc** or **E** shuts the table.

  Lay things on the grid as the recipe says and take what they make from the
  slot at its right. **The book** at its left knows every recipe whose
  ingredients you have found, and lays one out when pressed. Whatever the mouse
  is on says what it is: what it does, what it goes into, what the trader
  gives for it.
- **The panel** at its right is the party: a weapon, a helmet, a chestplate,
  boots and a charm each. Experience fills levels, shown in green; the `+` on
  a hero spends them on that hero.
- **The enchanting table** spends them on what the heroes carry instead: put a
  weapon or a piece of armour on it, lapis beside it, and choose one of what
  it offers.
- **The trader** keeps a stall past the wheat. He buys what the waves leave
  —so many of a thing for an emerald— and sells, for emeralds, potions, TNT,
  lapis, bottles of experience and more. What he wants changes with the land;
  each offer can be taken so many times, and he has all of it again when the
  next wave starts. Chests leave emeralds now and then too.
- **The mine** digs by itself: press it to fetch what it has. A better pickaxe
  finds more. **The furnace** turns raw iron and raw gold into ingots, with
  coal or sticks. **The wheat** grows by itself: press it when it is golden.
- All three go on while the game is put away or closed (up to eight hours),
  and the party holds its land meanwhile; what they did is told when you come
  back.
- `auto`, on the table, lets the camp do all of that by itself: craft, hand
  things over, spend its levels on the heroes, feed the furnace, fetch and reap.
- The other pages of the table are the **bestiary** (everything you have met,
  how many have fallen and what they left) and the **feats**.

**Over the whole screen**

The field lies along the bottom edge, but what happens on it does not stay
there. A blast sends a ring through your desktop that bends your windows as it
passes, and the screen shakes; the lightning comes down crooked from the top
of the monitor; endermen step out to anywhere on the screen and look down from
over your windows before they come back; slimes drop from the top edge, and
spiders come down on threads of their own. Before a lord comes, its shadow,
far bigger than it, crosses the screen behind everything, and its steps are
felt. (The bending is pleamar reading what is behind the game: a scene's own
shader can, on a compositor that lets the screen be captured.)

**What flies**

Some foes do not walk at all. Phantoms wheel over the screen in the
overworld's later waves and dive at the party; ghasts float high over the
Nether and spit fireballs — **press a fireball to send it back**, and it
fells the ghast that threw it. At the End's third wave the Ender Dragon comes,
loops over your whole desktop and swoops down along the field breathing; the
wave is not won while it lives. The archer and the witch shoot at what flies
when nothing on the ground is within reach, the lightning goes for the dragon,
and anything up there can be pressed to strike it.

Your game is kept in `~/.local/share/pleamar/guard/guard5.json`.

## The pictures

Every picture in `pieces/` is made by the scripts in `art/`: the characters and
blocks are built box by box and rendered with Blender (`make.py`), packed into
sheets that share pleamar's one square of pictures (`pack.py`), and the things
are written out pixel by pixel (`items.py`). `art/build.sh` makes them all again; it needs Blender and
Python's Pillow.

## Rights

- **No file of Mojang's is in here.** No texture, model, sound or font of
  Minecraft's was copied: the pictures come from the scripts in `art/`, and the
  sounds are tones made while it runs.
- **The characters, creatures and names are Mojang's all the same.** The
  creeper, the enderman, the Nether, the End and the rest belong to Mojang
  Studios and Microsoft, and what is drawn here imitates them on purpose. That
  makes this a fan work: to play and to share for free, **not to sell**. No
  licence in this repository gives anyone a right over them.
- "Minecraft" is a trademark of Mojang Synergies AB. This project is not
  theirs, is not endorsed by them, and does not use their name as its own.
- **The font** is [Monocraft](https://github.com/IdreesInc/Monocraft) by Idrees
  Hassan, under the SIL Open Font License 1.1 (`fonts/OFL.txt`).
- **The code** (`guard.plm`, `guard.luau`, `logic/`, `art/`, `play.sh`) is under the MIT
  licence ([LICENSE](LICENSE)): take it, change it, build your own game on it.
  That licence covers what was written here, the code and the drawing scripts.
  It does not, and cannot, cover Mojang's characters and names: a game made
  from this one with them in it is a fan work as this one is.
