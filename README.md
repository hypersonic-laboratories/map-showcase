# HELIX Map Showcase Package

Welcome to the [HELIX](https://helixgame.com/) Map Showcase Package! This package allows you to showcase your map created in Unreal Engine 5 (UE5) within the HELIX platform. It provides a user-friendly way for artists to present their map creations, enabling viewers to explore and appreciate the details and design of the maps.

This package is currently being used by the following official worlds: 
- [[Map Showcase] RP Downtown Tits](https://helixgame.com/worlds/e00887d.lix)
- [[Map Showcase] RP SCP](https://helixgame.com/worlds/oa3ac6d.lix)
- [[Map Showcase] Rural Area](https://helixgame.com/worlds/sd0da91.lix)

## Note
You will need to know how to install packages to your existing project. For a tutorial on that see [here](https://docs.helixgame.com/docs/getting-started/video-tutorials/creating-your-first-world).
## Features

- **Camera Placement**: Administrators can place cameras anywhere in the map to provide specific views and perspectives.
- **User Navigation**: Users can navigate through the cameras to explore the map as the creator intended.
- **Noclip Mode**: Users can freely navigate the map using the noclip (freecam) mode for an unrestricted view.
- **Easy Camera Management**: Adding and removing cameras is straightforward with an intuitive hotkey system.

**Note:**
Add yourself as an Admin if you want to modify/add the display cameras. Do so by editing the package's `Config.lua` file, under the section `'Config.Admins'`

## Local Server Installation

1. Clone or download the repository, and unzip it into your `Server/Packages` folder.
2. Rename the **Package** folder to `map-showcase`.
3. Update the spawn point according to your map in the `Config.lua` file.
4. Add yourself as an admin in the `Config.lua` file.
5. Set up your local database information in the `Config.lua` file.
6. Open your `Server/Config.toml` file.
7. Add `map-showcase` to your `game-mode` section.
8. Add your map package in the `map` section of `Config.toml` (default is `default-blank-map`).
9. Start your server.

### Config.toml Example
![Config.toml Example](https://github.com/hypersonic-laboratories/map-showcase/assets/67294331/e7640afa-1e0e-4412-86a5-97c468db1db6)

### Config.lua Example
![Config.lua Example](https://github.com/hypersonic-laboratories/map-showcase/assets/67294331/7418095d-6dbb-46c2-bf5d-2a48ad1a9c05)

## HUB Installation

1. Clone or download the repository.
2. Update the spawn point according to your map in the `Config.lua` file.
3. Add yourself as an admin in the `Config.lua` file.
4. Upload it to your world depot.
5. Set your game mode in your world config.
6. Set your map in your world config (default is `default-blank-map`).
7. Start or restart your hosting.

### HUB Config Example
![HUB Config Example](https://github.com/hypersonic-laboratories/map-showcase/assets/67294331/c4231a34-83ba-457b-9c63-46f8e010c813)

### Config.lua Example
![Config.lua Example](https://github.com/hypersonic-laboratories/map-showcase/assets/67294331/e1822d9b-105d-4ae7-8154-2ead913162a8)

---

Thank you for using the [HELIX](https://helixgame.com/) Map Showcase Package. We hope it enhances your map showcasing experience!
