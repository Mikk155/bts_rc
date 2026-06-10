# Contributing to Black Mesa Training Simulation: Resonance Cascade (bts_rc)

Thank you for your interest in contributing to the simulation! This repository contains the maps, custom weapons, entity overriders, and custom game logic for the Sven Co-op mod.

To ensure quality and consistency across all community contributions, please follow these guidelines and conventions.

---

## Local Environment Setup

1. **Clone the Repository**
   Navigate to your `Sven Co-op/svencoop/` directory and clone this repository under the folder name `svencoop_event_bts`. This directory name is critical to allow the event system to override local assets correctly:
   ```bash
   cd "C:\Program Files (x86)\Steam\steamapps\common\Sven Co-op\svencoop"
   git clone https://github.com/Mikk155/bts_rc.git svencoop_event_bts
   ```

2. **Download Third-Party Dependencies**
   Navigate to the `src` folder inside the cloned repository and run the dependency download script:
   ```bash
   cd svencoop_event_bts/src
   python fetch_dependancies.py
   ```
   This will download any required libraries (such as Mikk's custom JSON parser and utility collections) into the `scripts/` directory.

---

## Repository Structure

- [`.github/`](file:///c:/Users/akira/OneDrive/Desktop/bts_rc2/.github) - GitHub Actions workflows, issue templates, and pull request template.
- [`docs/`](file:///c:/Users/akira/OneDrive/Desktop/bts_rc2/docs) - Documentation website served via GitHub Pages (includes the JSON Schema visualizer).
- [`resource/`](file:///c:/Users/akira/OneDrive/Desktop/bts_rc2/resource) - UI localization files and resource definitions.
- [`scripts/maps/bts_rc/`](file:///c:/Users/akira/OneDrive/Desktop/bts_rc2/scripts/maps/bts_rc) - Contains the AngelScript game logic and hooks.
  - `gamemodes/` - Gameplay mods (e.g. inventory tracking, spectator managers).
  - `entities/` - Custom entity scripts and helpers.
  - `Hooks/` - Engine event hooks (player think, player spawn, disconnects).
- [`src/`](file:///c:/Users/akira/OneDrive/Desktop/bts_rc2/src) - Python automation tools (license checking, dependency fetchers).

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
   - **Global/Namespace Variables**: Prefix with `gp` or `g_` (e.g., `gpBufferDirty`, `g_logger`)

---

## License Headers

Every `.as` script must contain the MIT license header. Do not write this manually! 

Before committing your changes, run the licensing utility to automatically format and apply headers to all new or modified `.as` files:
```bash
python src/apply_license.py
```

---

## Verification & Pull Requests

### Pre-PR Checklist

Before opening a Pull Request, please follow this sequence of steps to ensure your changes pass our automated checks:

1. **Format and License Headers**: Run the license utility to apply headers to all new or modified `.as` files:
   ```bash
   python src/apply_license.py
   ```
2. **Run Build Validation**: Run the validation script to ensure metadata and JSON files compile:
   ```bash
   python src/main.py
   ```
3. **Verify Git Status**: Run `git status` to ensure all generated changes (like license headers) are included in your commit and your working tree is clean.
4. **Manual Test**: Run the map locally in Sven Co-op and confirm that your logic executes without compilation warnings or runtime script errors in the console.

### Submitting a Pull Request

- Create a new branch for your feature or bug fix: `git checkout -b feature/my-new-feature`
- Commit your changes with clear, descriptive commit messages.
- Push your branch and open a Pull Request targeting the `main` branch.
- Be sure to complete the Pull Request checklist provided in the template!
