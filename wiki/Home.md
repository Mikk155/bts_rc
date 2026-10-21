# bts_rc Wiki

Welcome to the **bts_rc** documentation. These pages describe the project's gameplay systems and the details map designers need when building or testing levels.

This page summarizes the bts_rc systems that affect level layout, entity placement, and testing. The project's `scripts/maps/bts_rc/bts_rc.fgd` contains the entity definitions used by the map editor.

## Map configuration

The shipped defaults are in `scripts/maps/bts_rc/default_config.json`. The server/map configuration is loaded from `scripts/maps/store/bts_rc.json`; use that file for per-installation overrides. The schema is generated next to it when running the map for a first time.

Several systems that directly affect level balance are configurables. Refeer to schema as there is no direct documentation to these.

## Gameplay and map design

- [Monster impact effects](effects)
- [Death drops](deathdrop)
- [Playable characters and view-model hands](characters)
- [Player data tracker](datatracker)

## Project documentation

- [Changelog formatting rules](changelog)
