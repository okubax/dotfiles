# Verdigris Dark palette

An original palette, built from scratch — not a port of anything. The idea
is oxidized copper on a weathered patina: a desaturated teal-charcoal (dark)
or warm parchment (light) neutral range, one warm copper/terracotta accent,
and a small set of muted, naturalistic hues for the semantic roles (rust
red, patina green, dull gold, dusty plum) rather than saturated primaries.

| role        | hex     |
|-------------|---------|
| bg          | #14201E |
| bg_alt      | #1B2A27 |
| bg_panel    | #223531 |
| bg_panel_alt | #2C423D |
| bg_header   | #35504A |
| fg          | #DCEDE8 |
| fg_muted    | #7FA69C |
| border      | #4C6B64 |
| accent      | #E08D4B |
| link        | #4FB3A9 |
| red         | #D9634B |
| green       | #7FB069 |
| yellow      | #E0B84B |
| purple      | #A97CA5 |

## Terminal ANSI mapping

Verdigris has no true blue or cyan in its palette, so kitty's `color4`
(blue) and `color6` (cyan) slots are filled by `link` (the teal accent) —
a common technique for palettes with fewer than eight distinct hues.
`accent` (copper) doubles as the "bright red"/orange slot, following the
common convention of treating orange as an intensified red rather than
inventing a slot for it.
