# AGENTS.md

MacroManager is a UI layer on top of Blizzard's existing macro system,
supporting Retail, Cata, Wrath, TBC (Anniversary), and Vanilla Classic via
per-flavor TOC files. When replicating stock behavior (link insertion, icon
picking, macro editing), mirror Blizzard's own implementation instead of
hand-rolling it — hand-rolled logic is what drifts out of sync when Blizzard
restructures an API.

## TOC / interface versions

Files: `MacroManager.toc` (Retail), `MacroManager_Cata.toc`,
`MacroManager_Wrath.toc`, `MacroManager_TBC.toc`, `MacroManager_Vanilla.toc`,
same under `MacroManagerData/`. Classic progression realms keep advancing
expansions, so don't infer the flavor from a folder name — confirm it.

To find the current interface number, don't guess from memory:

1. Check [Warcraft Wiki's TOC format page](https://warcraft.wiki.gg/wiki/TOC_format)
   — it has a community-maintained table of current interface numbers per
   flavor. Default source.
2. Cross-check against the real client: in-game `/dump select(4, GetBuildInfo())`,
   or the `.build.info` file at the WoW install root.
3. Cross-referencing another actively-updated installed addon's TOC is a
   sanity check, not a primary source.

A wrong interface number doesn't error — the addon just silently fails to
load. If a change does nothing in-game with no error, check the interface
number and the AddOns list (character select) before suspecting the Lua.

## When an API-dependent feature silently stops working

No error, nothing happens = Blizzard likely restructured the function you're
calling/hooking. A `hooksecurefunc` on a global that still exists but isn't
the real call site anymore hooks "successfully" and just never fires.

1. Add a temporary `print()` at the top of the hook to confirm if it fires.
   Relog (not `/reload`) to test. Remove the print once fixed.
2. If it doesn't fire, read Blizzard's actual current source instead of
   guessing — [Gethe/wow-ui-source](https://github.com/Gethe/wow-ui-source)
   mirrors it, with one branch per flavor (`classic_anniversary`, `classic`,
   `classic_era`, `live`, etc). For anything macro-related, check
   `Blizzard_MacroUI` first — it's the stock macro editor and the most
   direct reference. Download raw files and grep locally; `WebFetch`'s
   summarizer truncates large FrameXML files and will falsely report things
   as "not found."
3. Hook whatever the real current entry point turns out to be, guarded with
   existence checks so it degrades gracefully if it moves again.

## Local dev / testing

Symlinking into a WoW AddOns folder needs an elevated shell or Windows
Developer Mode — and even with Developer Mode on, a non-elevated shell may
still lack the symlink privilege (`whoami /priv`). If so, run the `New-Item
-ItemType SymbolicLink` from a one-off elevated child process
(`Start-Process powershell -Verb RunAs -Wait`) to trigger a UAC prompt.

Confirm the symlink will succeed before deleting the existing AddOns folder
it's replacing.
