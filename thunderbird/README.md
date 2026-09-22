# Thunderbird theming — Litho / Vellum / Daguerre / Verdigris

Same system as `../firefox/README.md`, applied to Thunderbird's chrome
(toolbar, tab bar, folder pane, thread pane, message-pane chrome, menus).
Thunderbird shares Firefox's Toolkit/XUL widgets for toolbars, tabs, and
menus, so most of the CSS is the same shape; the folder pane and thread
pane are styled via the older `::-moz-tree-*` pseudo-elements since most
current Thunderbird builds still use the XUL tree widget there.

The message body itself (the actual email content) is intentionally
**not** touched — it renders in a sandboxed, restricted content area for
privacy/security reasons, and userChrome/userContent CSS can't and
shouldn't reach into it.

## Where the colors come from

Same generator as Firefox: `~/.cfg-tzevaot/bin/gen-browser-themes.py`,
same `PALETTES` source of truth. Re-run it after changing a palette.

## Layout

```
thunderbird/
  litho/dark/userChrome.css
  litho/light/...
  vellum/dark/... , vellum/light/...
  daguerre/dark/... , daguerre/light/...
  verdigris/dark/... , verdigris/light/...
  active -> <family>/<variant>
```

No `userContent.css` here — Thunderbird has nothing equivalent to
Firefox's about:newtab/about:blank worth theming, and message bodies are
deliberately off-limits (see above).

## Profile wiring (one-time, already done)

Live profile: `~/.thunderbird/eii7hya3.default-release` (confirmed via its
`.parentlock`, tied to the manual install at `~/.thunderbird`).

```
<profile>/chrome/userChrome.css -> @import "file://<home>/.cfg-tzevaot/thunderbird/active/userChrome.css";
<profile>/user.js               -> user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
```

## Switching

Same four commands, no separate `thunderbird-theme` script:

```
litho-theme dark|light|toggle|status
vellum-theme dark|light|toggle|status
daguerre-theme dark|light|toggle|status
verdigris-theme dark|light|toggle|status
```

**Restart Thunderbird to see the change** — not hot-reloaded.

## Known limits

Thunderbird's UI (Supernova and onward) has been changing faster than
Firefox's; if a future build replaces the folder/thread pane XUL trees
with an HTML view, the `::-moz-tree-*` rules in this file stop matching
anything (harmlessly — they just won't apply) and would need replacing.
The toolbar/tab/menu rules ride on the same stable Toolkit widgets Firefox
uses and are much less likely to need touching.
