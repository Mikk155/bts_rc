# Contributing to Black Mesa Training Simulation: Resonance Cascade (bts_rc)

Thank you for your interest in contributing to the simulation! This repository contains the maps, custom weapons, entity overriders, and custom game logic for the Sven Co-op mod.

To ensure quality and consistency across all community contributions, please follow these guidelines and conventions.

---

## Local Environment Setup

1. **Clone the Repository**
   Navigate to your `Sven Co-op/` directory and clone this repository under the folder name `svencoop_event_bts`. This directory name is critical to allow the event system to override local assets correctly:
   ```bash
   cd "C:\Program Files (x86)\Steam\steamapps\common\Sven Co-op"
   git clone https://github.com/Mikk155/bts_rc.git svencoop_event_bts
   ```
   Open the console on your initialized client and type:
   ```
   ev_list
   ```
   You should get an output like this:
   > [0] name: 'bts', title: 'Black Mesa Training Simulation: Resonance Cascade'<br>
   > folder: 'svencoop_event_bts', priority: 1<br>
   > date: 2026-01-01 00:00:00 - 2026-12-31 23:59:59<br>
   > enabled: yes, forced: no<br>
   > content: UI - yes, GAME - yes<br>
   > active: UI - yes, GAME - yes
   If for some reason it refuses to load you can enable it:
   ```
   ev_enable bts
   ```

2. **Download Third-Party Dependencies**
   Navigate to the `src` folder inside the cloned repository and run the main script
   ```bash
   cd svencoop_event_bts/src
   python main.py
   ```
   This will download all the third party angelscript utility files into the working directory.

   To fetch game assets such as models, sounds and sprites, verify the last release at [Github](https://github.com/Mikk155/bts_rc/releases).

---

## Repository Structure

- [`.github/`](.github/) - GitHub Actions workflows, issue templates, and pull request template.
- [`docs/`](docs/) - Documentation
  - [`page/`](docs/page/) - Github pages web site.
  - [`src/`](docs/src/) - TypeScript sources for Github pages web site.
<!--
- [`resource/`](resource/) - UI localization files and resource definitions.
Sven Co-op events currently does not support GameMenu.res replacement.
-->
- [`scripts/maps/bts_rc/`](scripts/maps/bts_rc/) - Contains the AngelScript game logic and hooks.
  - [`gamemodes/`](scripts/maps/bts_rc/gamemodes/) - Gameplay mods (e.g. inventory tracking, spectator managers).
  - [`entities/`](scripts/maps/bts_rc/entities/) - Custom entity scripts and helpers.
  - [`Hooks/`](scripts/maps/bts_rc/Hooks/) - Engine event hooks (player think, player spawn, disconnects).
- [`src/`](src/) - Python automation tools (license checking, dependency fetchers, release generator).
- [`wiki/`](src/wiki/) - Markdown docuentation for Github's "Wiki" section.

---

## Code Style Guide

All AngelScript scripts should match the formatting conventions enforced by the project configuration.

1. **Brace Wrapping (Allman Style)**
   Place opening and closing braces on their own line:
   ```as
   void Think( CBasePlayer@ player )
   {
       if( player !is null )
       {
           // Do something
       }
   }
   ```

2. **Spaces and Indentation**
   - Use **4 spaces** for indentation. Do not use tabs.
   - Insert spaces inside parentheses for function parameters, conditionals, and casts:
     - `if( player !is null )` (Correct)
     - `if(player!isnull)` (Incorrect)
     - `cast<CBaseEntity@>( entity )` (Correct)

3. **Naming Conventions**
   - **Namespaces & Classes**: PascalCase (e.g., `namespace item_tracker`)
   - **Functions**: PascalCase (e.g., `void UpdatePlayerInventory`)
   - **Local Variables**: camelCase (e.g., `string trackedStr`)
   - **Global/Namespace Variables**: Prefix with `gp` (e.g., `gpBufferDirty`) for global parameters or instead use `g_` (e.g., `g_logger`) for global parameters that should be accessed by one or more external structures.

---

## Checkers

Every `.as` script must contain the MIT license header. Do not write this manually! 

Before committing your changes, run the python utility to run various tests and format the AngelScript files:
```bash
python src/main.py
```

- If the program exit with return code 0 it's ready to go!

---

## Verification & Pull Requests

### Pre-PR Checklist

Before opening a Pull Request, please follow this sequence of steps to ensure your changes pass our automated checks:

1. **Run Build Validation**: Run the validation script to ensure metadata and JSON files compile:
   ```bash
   python src/main.py
   ```
2. **Verify Git Status**: Run `git status` to ensure all generated changes (like license headers) are included in your commit and your working tree is clean.
3. **Manual Test**: Run the map locally in Sven Co-op and confirm that your logic executes without compilation warnings or runtime script errors in the console.
4. **Change log**: Add a new entry on the top of the [changelog](CHANGELOG.md) file following the format used explained [here](https://github.com/Mikk155/bts_rc/wiki/changelog)

### Submitting a Pull Request

- Create a new branch for your feature or bug fix: `git checkout -b feature/my-new-feature`
- Commit your changes with clear, descriptive commit messages.
- Push your branch and open a Pull Request targeting the `main` branch.
- Be sure to complete the Pull Request checklist provided in the template!
