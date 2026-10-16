# Release Packaging & Deployment Guide

This guide defines the packaging standards, archive directory hierarchy, and naming conventions for releases of **Dynamic Region Graphics**.

---

## 1. Archive Naming Convention

The release zip must be saved in the parent directory and strictly named:
```
DynamicRegionGraphics_v<VERSION>.zip
```
Example: `DynamicRegionGraphics_v1.0.0.zip`

---

## 2. Archive Directory Structure

The archive must unpack cleanly into the root of the user's *The Witcher 3* installation directory (`The Witcher 3\`).

```
DynamicRegionGraphics_v<VERSION>.zip
├── bin/
│   └── config/
│       └── r4game/
│           └── user_config_matrix/
│               └── pc/
│                   └── modDynamicRegionGraphics.xml
└── mods/
    └── modDynamicRegionGraphics/
        └── content/
            ├── scripts/
            │   └── local/
            │       ├── DynamicRegionGraphicsHooks.ws
            │       ├── DynamicRegionGraphicsManager.ws
            │       └── DynamicRegionGraphicsOptions.ws
            ├── ar.w3strings
            ├── br.w3strings
            ├── cn.w3strings
            ├── cz.w3strings
            ├── de.w3strings
            ├── en.w3strings
            ├── es.w3strings
            ├── esmx.w3strings
            ├── fr.w3strings
            ├── hu.w3strings
            ├── it.w3strings
            ├── jp.w3strings
            ├── kr.w3strings
            ├── pl.w3strings
            ├── ru.w3strings
            ├── tr.w3strings
            ├── ua.w3strings
            └── zh.w3strings
```

> **Note on Exclusions:**
> - Do NOT include source CSV files (`localization/*.csv`) in the release zip.
> - Do NOT include decoder artifacts (`*.w3strings.csv`).
> - Do NOT include temporary scratch files or `.agents` guides in the release zip.

---

## 3. Automated Packaging Script (Python)

The mod version is defined in **one single place**: `GetDRGVersion()` inside `content/scripts/local/DynamicRegionGraphicsOptions.ws`.
The packaging script `tools/package.py` automatically extracts this version and builds the release zip.

To package a release, simply run:
```powershell
python tools/package.py
```

The script extracts the version from `DynamicRegionGraphicsOptions.ws` and creates `DynamicRegionGraphics_v<VERSION>.zip` containing `bin/` and `mods/modDynamicRegionGraphics/content/`.
