# Contributing Guidelines

This document outlines the workflow, coding standards, and architectural conventions for developers and AI coding assistants contributing to **Dynamic Region Graphics**.

---

## 1. Environment & Path Standards

- **No Machine-Specific Paths:** Never commit hardcoded local filesystem paths (e.g., personal drive letters, user folder paths, or machine-specific steam directories).
- Always reference paths relatively or with clear portable placeholders:
  - Repository Root: `<Repo-Root>`
  - Game Directory: `<Witcher3-Root>`
  - Deployed Mod: `<Witcher3-Root>/mods/modDynamicRegionGraphics/`
  - Deployed XML: `<Witcher3-Root>/bin/config/r4game/user_config_matrix/pc/modDynamicRegionGraphics.xml`
- Run tools from repository root using relative paths:
  ```powershell
  python tools/generate_strings.py
  python tools/package.py
  ```

---

## 2. WitcherScript Architecture & Rules

- **Native Annotations Only:**
  - Never replace or overwrite vanilla game `.ws` files.
  - Use REDengine annotations (`@addField`, `@wrapMethod`, `@addMethod`) to cleanly extend game classes (`CR4Game`, `CCommonMapManager`, `CR4Player`).
  - Always call `wrappedMethod(...)` inside `@wrapMethod`.
- **WitcherScript Instantiation Syntax:**
  - In WitcherScript, dynamic allocations must use `new ClassName in parent;` without parentheses (e.g., `drgManager = new DynamicRegionGraphicsManager in this;`).
- **Baseline Preservation:**
  - Never destroy or permanently overwrite the player's personal rendering configuration.
  - All baseline settings must be cached upon session start so Profile 0 (`Default`) accurately restores the player's custom settings.

---

## 3. Localization Standards

- **Zero Hash Collision Policy:**
  - Never use generic string keys such as `General`, `panel_General`, `Graphics`, or `Video`.
  - Always prefix custom keys with `DRG_` or `msg_drg_` to prevent collisions with vanilla REDengine string hashes (such as `0xb38875ad` for `panel_general`).
- **18-Language Support:**
  - All user-facing strings must have genuine translations for all 18 supported languages in `tools/generate_strings.py`.
  - Never use English text as a placeholder or silent fallback for other languages.
- **Workflow:**
  - Update `TRANSLATIONS` in `tools/generate_strings.py`.
  - Run `python tools/generate_strings.py` to regenerate all binary `.w3strings` and reference CSVs.

---

## 4. Packaging & Releases

- **Version Management:**
  - The mod version is maintained in a single source of truth: `GetDRGVersion()` inside `content/scripts/local/DynamicRegionGraphicsOptions.ws`.
  - Release archives are created with:
    ```powershell
    python tools/package.py
    ```
- **Archive Cleanliness:**
  - Release archives must contain only `bin/` and `mods/modDynamicRegionGraphics/content/`.
  - Source CSV files, development scripts, and temporary files must never be packaged into release distributions.

---

## 5. Pre-Commit Verification Checklist

Before committing changes:
1. Verify that scripts compile cleanly without errors:
   ```powershell
   & "<Witcher3-Root>/bin/x64_dx12/witcher3.exe" -compileScripts
   ```
2. Verify that lingering compiler processes are stopped.
3. Verify that `tools/generate_strings.py` and `tools/package.py` execute cleanly.
4. Ensure no machine-specific absolute paths or temporary build artifacts are committed.
