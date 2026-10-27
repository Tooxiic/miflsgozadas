# Obsidian Ultra restoration

Recovered Library.lua snapshot: 2026-08-28 12:36:14 UTC.
Source: https://web.archive.org/web/20260828123614id_/https://raw.githubusercontent.com/joustingmatch/ObsidianUltra/main/Library.lua

Original SHA-256: 1c8ed0db30a788886cee57f040fc50e6865d86037d5270d2ea78cfe075751da6

The Wayback CDX prefix query found one archived ObsidianUltra file, Library.lua. This restores that snapshot, not an unverified later revision or every file that may have existed in the deleted repository.

Two URLs in Library.lua changed, and an optional local icon-module fallback was added: the four image assets now load from this repository, and the Lucide module is vendored here. The native sidebar, AddSubTab and SingleColumn behavior are preserved.

Assets and MIT license: deividcomsono/Obsidian. Icon module, two spritesheets and MIT license: mstudio45/lucide-roblox-direct, retrieved 2026-10-26. These dependencies are current upstream files, not recovered ObsidianUltra snapshots.

Compact sidebar customization: optional CompactTabButtons renders 18px icons inside rounded 32px buttons without borders. SubTabsInSidebar=false keeps subtab navigation in the horizontal content bar. newUi.lua enables both options and requires the compact-v2 library revision to reject stale local/cache copies.

compact-v4: switch labels wrap inside their reserved width and each row expands to the measured text height. UI-only runtime verification confirmed TextFits=true for short and multi-line labels with space left before every switch.
