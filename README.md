# Meowicorn's Donut Adventure

An endless runner about a fat unicorn cat who lives in the clouds and would do anything for a donut.

Run, jump and duck past puddles, angry dogs and crying rain clouds. Grab a golden donut and take off, flapping through the sky for chains of donuts. Spend what you collect in the Shop to unlock seven more cats, each with her own perk, stats and voice.

Made in Godot 4.7 for Jumpstart Hack Club.

## Play it

Play in your browser (no install): [wthaarushi.itch.io/meowicorns-donut-adventure](https://wthaarushi.itch.io/meowicorns-donut-adventure)

## Run it locally

You need [Godot 4.7](https://godotengine.org/download) (the standard build, not .NET).

1. Clone or download this repo:
   ```
   git clone https://github.com/wthaarushi/meowicorns-donut-adventure.git
   ```
2. Open Godot, click **Import**, and pick the `project.godot` file inside the folder.
3. Press **F5** (or the Play button in the top right) to run the game.

The first launch takes a few seconds while Godot imports the art and audio. Progress is saved to Godot's user data folder, so your donuts and unlocked cats stick around between runs.

To build the web version yourself: **Project → Export → Web → Export Project**. You will need the export templates installed (Editor → Manage Export Templates).

## Controls

| Key | Action |
| --- | --- |
| Space / Up / W | Jump, or flap while flying |
| S / Down | Duck, or dive in the air |
| R | Restart |
| B | Shop |
| H | How to play |
| M / Esc | Settings, pause |

## Project layout

```
scenes/    main scene
scripts/   game logic
art/       pixel art (cats live in art/cats)
audio/     sound effects and music
fonts/     Press Start 2P (SIL Open Font License)
tools/     make_cat.py and make_dog.py regenerate the sprite sheets
```

All art, sounds and music were made for this project.
