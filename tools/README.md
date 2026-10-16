# Build & Localization Tooling

This directory contains standalone Python development utilities used to generate localizations and package release archives for **Dynamic Region Graphics**.

---

## Tool Overview

### 1. `generate_strings.py` — Translation Master & Compiler
- **Purpose:** Serves as the single source of truth for all mod menu and notification translations across 18 supported languages.
- **How it works:**
  - Maintains a master translation dictionary covering 18 game languages (EN, RU, PL, DE, FR, IT, ES, ESMX, BR, CZ, HU, JP, KR, ZH, CN, TR, AR, UA).
  - Computes REDengine FNV-style string key hashes for each option and title.
  - Automatically exports human-readable CSV files to the `localization/` directory for reference and REDkit compatibility.
  - Compiles binary `.w3strings` packages directly into `content/` (and synchronizes them with the installed game mod folder if present).
- **Usage:**
  ```powershell
  python tools/generate_strings.py
  ```

---

### 2. `w3strings_nextgen.py` — Binary W3Strings Engine
- **Purpose:** Low-level encoder and decoder for The Witcher 3 Next-Gen binary string files (`.w3strings`, version 164).
- **How it works:**
  - Implements the REDengine custom 6-bit / 7-bit variable-length integer decoding and Blowfish / XOR key tables for each language.
  - Computes deterministic string key hashes matching the native REDengine hash algorithm (`hash_key(key)`).
  - Used as an importable module by `generate_strings.py`, but can also be used standalone from the command line to encode/decode individual CSVs and `.w3strings` files.
- **Standalone Usage:**
  ```powershell
  # Encode a CSV into binary w3strings
  python tools/w3strings_nextgen.py --encode localization/en.csv -l en -o content/en.w3strings

  # Decode binary w3strings back to CSV
  python tools/w3strings_nextgen.py --decode content/en.w3strings -l en -o localization/en.csv
  ```

---

### 3. `package.py` — Release Packager
- **Purpose:** Builds a distribution-ready `.zip` archive formatted for direct drag-and-drop installation into The Witcher 3 root directory.
- **How it works:**
  - Reads the mod version directly from `GetDRGVersion()` in `content/scripts/local/DynamicRegionGraphicsOptions.ws` (single source of truth).
  - Collects the in-game options menu (`bin/config/.../modDynamicRegionGraphics.xml`).
  - Collects scripts and compiled `.w3strings` from `content/` into `mods/modDynamicRegionGraphics/content/`.
  - Automatically filters out development files, source CSVs, python caches, and temporary files.
  - Generates `DynamicRegionGraphics_v<VERSION>.zip` in the parent directory.
- **Usage:**
  ```powershell
  python tools/package.py
  ```
