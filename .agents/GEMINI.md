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

5. **Packaging & Release Rules:**
   - Always archive releases following the exact structure and filename specified in [.agents/packaging.md](packaging.md).
   - Use `python tools/package.py` to create the release archive.
   - **Release Consistency:** The git tag (`v<VERSION>`), release title, archive name, and `GetDRGVersion()` in `DynamicRegionGraphicsOptions.ws` must be strictly identical.
   - **Automated Release Notes:** Release descriptions on GitHub must never contain manually written free-form text; use only GitHub's automatically generated release notes comparing against the previous release.

6. **Rule of Truth & Fact Verification (CRITICAL):**
   - The assistant must never make assumptions or claim that a technology, feature, version, or fact does not exist simply because it is unfamiliar or beyond its static training data.
   - If the assistant doubts the existence, accuracy, or state of any information (e.g. newer hardware/software releases, versions, APIs), it is **strictly required to search and verify** the information before making statements or drawing conclusions.

7. **Rule of Absolute Instruction Compliance (CRITICAL):**
   - The assistant must adhere strictly and unconditionally to user instructions regarding tools, models, workflows, and subagent configurations.
   - When the user specifies a specific model for a subagent (such as `flash_lite`), the assistant must use that exact model without deviation or arbitrary substitution.

8. **User/Player Communication Rule (No Markdown & No Tech Explanations):**
   - When drafting messages or replies for players/end users (Nexus Mods comments, direct messages, forum posts):
     - **NO MARKDOWN:** Output strictly plain raw text. Do not use code blocks (` ``` `), bold/italic (`**`, `*`), headers (`#`), bullet asterisks, or inline backticks (` ` `). The text must be immediately ready for copy-pasting into text boxes without showing raw markdown syntax.
     - **NO TECHNICAL EXPLANATIONS:** Avoid developer jargon, internal code mechanics, memory offsets, assembly instructions, or architecture details. Formulate answers strictly from a player's perspective: simple, friendly, practical instructions focusing only on settings to toggle, menu options, or files to update.

9. **Git Commit Standards (Conventional Commits Only):**
   - All git commit messages must strictly follow the **Conventional Commits** specification:
     ```
     <type>[optional scope]: <description>
     ```
   - Allowed types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`.
   - Never use unstructured, generic, or non-conventional commit messages.

