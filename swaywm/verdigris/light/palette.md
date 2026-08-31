# Verdigris Light palette

An original palette, built from scratch — not a port of anything. The idea
is oxidized copper on a weathered patina: a desaturated teal-charcoal (dark)
or warm parchment (light) neutral range, one warm copper/terracotta accent,
and a small set of muted, naturalistic hues for the semantic roles (rust
red, patina green, dull gold, dusty plum) rather than saturated primaries.

| role        | hex     |
|-------------|---------|
| bg          | #F4EFE6 |
| bg_alt      | #EAE2D3 |
| bg_panel    | #DED2BC |
| bg_panel_alt | #CBBFA3 |
| bg_header   | #B9AC8E |
| fg          | #24312B |
| fg_muted    | #5C6F66 |
| border      | #8FA096 |
| accent      | #B85E24 |
| link        | #1F7A70 |
| red         | #A8402A |
| green       | #4C7A3A |
| yellow      | #96751C |
| purple      | #7A4F76 |

## Terminal ANSI mapping

Verdigris has no true blue or cyan in its palette, so kitty's `color4`
(blue) and `color6` (cyan) slots are filled by `link` (the teal accent) —
a common technique for palettes with fewer than eight distinct hues.
`accent` (copper) doubles as the "bright red"/orange slot, following the
common convention of treating orange as an intensified red rather than
inventing a slot for it.
