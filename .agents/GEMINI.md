# Dynamic Region Graphics — AI Assistant Guide

This document is the central entry point and reference for AI coding assistants working on the **Dynamic Region Graphics** mod for *The Witcher 3: Wild Hunt* (Next-Gen v5.00+).

---

## 1. Project Overview & Architecture

The mod dynamically switches ray tracing / path tracing settings and upscaler presets in *The Witcher 3* based on the active game region (e.g. Royal Palace in Vizima, Kaer Morhen, Novigrad/Velen, Skellige, Toussaint) and interior/exterior contexts, automatically reverting to baseline settings during combat.

### Key Directories
- `bin/config/r4game/user_config_matrix/pc/modDynamicRegionGraphics.xml` — Options menu configuration (groups, regions, interiors/exteriors, combat toggle, upscaling presets).
- `content/scripts/` — WitcherScript codebase:
  - `local/DynamicRegionGraphicsManager.ws` — Core runtime manager controlling region detection, interior/exterior tracking, combat state overrides, rendering options application, baseline caching, and notifications.
  - `local/DynamicRegionGraphicsOptions.ws` — Reads and holds user menu settings from `user.settings`.
  - `local/DynamicRegionGraphicsHooks.ws` — Modern WitcherScript annotations (@addField, @wrapMethod) hooking into CR4Game, CCommonMapManager, and CR4Player.
- `localization/` — Localization source CSVs (18 languages).
- `content/` — Compiled game package content:
  - `content/*.w3strings` — Binary localization strings (18 languages).
  - `content/scripts/local/` — Scripts directory deployed to the game.
- `tools/` — Standalone development tooling:
  - `tools/generate_strings.py` — Master translation dictionary and w3strings compiler.
  - `tools/w3strings_nextgen.py` — Low-level binary w3strings encoder/decoder engine.
  - `tools/package.py` — Release zip packaging script.
- `.agents/` — Assistant documentation and workflow guides:
  - `GEMINI.md` — This master guide.
  - `packaging.md` — Building release zips, folder structures, naming conventions.
  - `CONTRIBUTING.md` — Contribution guidelines and development standards.

---

## 2. Core Workflow & Rules

1. **Working Environments & Paths:**
   - Workspace Repository: `<Repo-Root>`
   - Deployed Mod Directory: `<Witcher3-Root>/mods/modDynamicRegionGraphics/`
   - Deployed Config Menu: `<Witcher3-Root>/bin/config/r4game/user_config_matrix/pc/modDynamicRegionGraphics.xml`

2. **Always Keep Deployed & Repo Copies Synced:**
   - Whenever scripts or `.w3strings` are modified, make sure they are updated both in repository source and deployed to `<Witcher3-Root>/mods/modDynamicRegionGraphics/`.
   - Update `modDynamicRegionGraphics.xml` in both repository and `<Witcher3-Root>/bin/config/...` folder.

3. **Verify Script Compilation:**
   - Run compilation check using:
     ```powershell
     & "<Witcher3-Root>/bin/x64_dx12/witcher3.exe" -compileScripts
     ```
   - Ensure the process terminates or kill lingering compiler instances with `Stop-Process -Name "witcher3" -Force`.

4. **Localization Safety Rule (CRITICAL):**
   - **Never** use generic keys like `General`, `panel_General`, `Graphics`, or `Video`.
   - Prefix all localized keys (e.g. `DRG_...`, `msg_drg_...`).
   - Maintain honest translations across all 18 languages without English fallbacks.

5. **Packaging:**
   - Always archive releases following the exact structure and filename specified in [.agents/packaging.md](packaging.md).
   - Use `python tools/package.py` to create the release archive.
