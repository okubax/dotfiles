" Name: solarized_light.vim
" Solarized Light: Ethan Schoonover's original palette. See
" ~/dotfiles/swaywm/solarized/README.md and light/palette.md for the
" full palette and where each value comes from.

set background=light
hi clear

if exists('syntax on')
    syntax reset
endif

let g:colors_name='solarized_light'
set t_Co=256

" bg          = "#FDF6E3"  (Solarized base3)
" bg_alt      = "#EEE8D5"  (Solarized base2)
" bg_panel    = "#C1C5BB"  (interpolated, base2->base1)
" bg_panel_alt= "#93A1A1"  (Solarized base1)
" fg          = "#657B83"  (Solarized base00)
" fg_muted    = "#93A1A1"  (Solarized base1)
" border      = "#839496"  (Solarized base0)
" accent      = "#268BD2"  (Solarized blue, unchanged from Dark)
" link        = "#6C71C4"  (Solarized violet, unchanged from Dark)
" red         = "#DC322F"  (Solarized red)
" green       = "#859900"  (Solarized green)
" yellow      = "#B58900"  (Solarized yellow)
" purple      = "#D33682"  (Solarized magenta)
" cyan        = "#2AA198"  (Solarized cyan)
" orange (2nd red/yellow hue) = "#CB4B16" — unchanged from Dark, see palette.md

hi Normal           guisp=NONE      guifg=#657B83   guibg=#FDF6E3   ctermfg=241     ctermbg=230  gui=NONE           cterm=NONE
hi Visual           guisp=NONE      guifg=NONE      guibg=#B7D9EF   ctermfg=NONE    ctermbg=153  gui=bold           cterm=bold

hi Conceal          guisp=NONE      guifg=#93A1A1   guibg=NONE      ctermfg=245      ctermbg=NONE gui=NONE           cterm=NONE
hi ColorColumn      guisp=NONE      guifg=NONE      guibg=#93A1A1   ctermfg=NONE    ctermbg=245  gui=NONE           cterm=NONE
hi Cursor           guisp=NONE      guifg=#FDF6E3   guibg=#268BD2   ctermfg=230     ctermbg=33   gui=NONE           cterm=NONE
hi lCursor          guisp=NONE      guifg=#FDF6E3   guibg=#268BD2   ctermfg=230     ctermbg=33   gui=NONE           cterm=NONE
hi CursorIM         guisp=NONE      guifg=#FDF6E3   guibg=#268BD2   ctermfg=230     ctermbg=33   gui=NONE           cterm=NONE
hi CursorColumn     guisp=NONE      guifg=NONE      guibg=#EEE8D5   ctermfg=NONE    ctermbg=254  gui=NONE           cterm=NONE
hi CursorLine       guisp=NONE      guifg=NONE      guibg=#EEE8D5   ctermfg=NONE    ctermbg=254  gui=NONE           cterm=NONE
hi Directory        guisp=NONE      guifg=#6C71C4   guibg=NONE      ctermfg=61      ctermbg=NONE gui=NONE           cterm=NONE
hi DiffAdd          guisp=NONE      guifg=#FDF6E3   guibg=#859900   ctermfg=230     ctermbg=64   gui=NONE           cterm=NONE
hi DiffChange       guisp=NONE      guifg=#657B83   guibg=#CB4B16   ctermfg=241     ctermbg=166  gui=NONE           cterm=NONE
hi DiffDelete       guisp=NONE      guifg=#FDF6E3   guibg=#DC322F   ctermfg=230     ctermbg=160  gui=NONE           cterm=NONE
hi DiffText         guisp=NONE      guifg=#FDF6E3   guibg=#268BD2   ctermfg=230     ctermbg=33   gui=NONE           cterm=NONE
hi EndOfBuffer      guisp=NONE      guifg=NONE      guibg=NONE      ctermfg=NONE    ctermbg=NONE gui=NONE           cterm=NONE
hi ErrorMsg         guisp=NONE      guifg=#DC322F   guibg=NONE      ctermfg=160     ctermbg=NONE gui=bold,italic    cterm=bold,italic
hi VertSplit        guisp=NONE      guifg=#839496   guibg=NONE      ctermfg=244     ctermbg=NONE gui=NONE           cterm=NONE
hi Folded           guisp=NONE      guifg=#6C71C4   guibg=#93A1A1   ctermfg=61      ctermbg=245  gui=NONE           cterm=NONE
hi FoldColumn       guisp=NONE      guifg=#93A1A1   guibg=#FDF6E3   ctermfg=245      ctermbg=230  gui=NONE           cterm=NONE
hi SignColumn       guisp=NONE      guifg=#839496   guibg=#FDF6E3   ctermfg=244     ctermbg=230  gui=NONE           cterm=NONE
hi IncSearch        guisp=NONE      guifg=#657B83   guibg=#CB4B16   ctermfg=241     ctermbg=166  gui=NONE           cterm=NONE
hi CursorLineNR     guisp=NONE      guifg=#268BD2   guibg=NONE      ctermfg=33      ctermbg=NONE gui=NONE           cterm=NONE
hi LineNr           guisp=NONE      guifg=#839496   guibg=NONE      ctermfg=244     ctermbg=NONE gui=NONE           cterm=NONE
hi MatchParen       guisp=NONE      guifg=#B58900   guibg=NONE      ctermfg=136     ctermbg=NONE gui=bold           cterm=bold
hi ModeMsg          guisp=NONE      guifg=#657B83   guibg=NONE      ctermfg=241     ctermbg=NONE gui=bold           cterm=bold
hi MoreMsg          guisp=NONE      guifg=#6C71C4   guibg=NONE      ctermfg=61      ctermbg=NONE gui=NONE           cterm=NONE
hi NonText          guisp=NONE      guifg=#839496   guibg=NONE      ctermfg=244     ctermbg=NONE gui=NONE           cterm=NONE
hi Pmenu            guisp=NONE      guifg=#657B83   guibg=#93A1A1   ctermfg=241     ctermbg=245  gui=NONE           cterm=NONE
hi PmenuSel         guisp=NONE      guifg=#FDF6E3   guibg=#268BD2   ctermfg=230     ctermbg=33   gui=bold           cterm=bold
hi PmenuSbar        guisp=NONE      guifg=NONE      guibg=#93A1A1   ctermfg=NONE    ctermbg=245  gui=NONE           cterm=NONE
hi PmenuThumb       guisp=NONE      guifg=NONE      guibg=#93A1A1   ctermfg=NONE    ctermbg=245   gui=NONE           cterm=NONE
hi Question         guisp=NONE      guifg=#6C71C4   guibg=NONE      ctermfg=61      ctermbg=NONE gui=NONE           cterm=NONE
hi QuickFixLine     guisp=NONE      guifg=NONE      guibg=#93A1A1   ctermfg=NONE    ctermbg=245  gui=bold           cterm=bold
hi Search           guisp=NONE      guifg=#657B83   guibg=#B7D9EF   ctermfg=241     ctermbg=153  gui=bold           cterm=bold
hi SpecialKey       guisp=NONE      guifg=#93A1A1   guibg=NONE      ctermfg=245      ctermbg=NONE gui=NONE           cterm=NONE
hi SpellBad         guisp=#DC322F   guifg=NONE      guibg=NONE      ctermfg=160     ctermbg=NONE gui=underline      cterm=underline
hi SpellCap         guisp=#CB4B16   guifg=NONE      guibg=NONE      ctermfg=166     ctermbg=NONE gui=underline      cterm=underline
hi SpellLocal       guisp=#6C71C4   guifg=NONE      guibg=NONE      ctermfg=61      ctermbg=NONE gui=underline      cterm=underline
hi SpellRare        guisp=#859900   guifg=NONE      guibg=NONE      ctermfg=64      ctermbg=NONE gui=underline      cterm=underline
hi StatusLine       guisp=NONE      guifg=#657B83   guibg=#93A1A1   ctermfg=241     ctermbg=245  gui=NONE           cterm=NONE
hi StatusLineNC     guisp=NONE      guifg=#93A1A1   guibg=#93A1A1   ctermfg=245      ctermbg=245  gui=NONE           cterm=NONE
hi TabLine          guisp=NONE      guifg=#93A1A1   guibg=#93A1A1   ctermfg=245      ctermbg=245  gui=NONE           cterm=NONE
hi TabLineFill      guisp=NONE      guifg=NONE      guibg=#93A1A1   ctermfg=NONE    ctermbg=245  gui=NONE           cterm=NONE
hi TabLineSel       guisp=NONE      guifg=#859900   guibg=#FDF6E3   ctermfg=64      ctermbg=230  gui=NONE           cterm=NONE
hi Title            guisp=NONE      guifg=#6C71C4   guibg=NONE      ctermfg=61      ctermbg=NONE gui=bold           cterm=bold
hi VisualNOS        guisp=NONE      guifg=NONE      guibg=#B7D9EF   ctermfg=NONE    ctermbg=153  gui=bold           cterm=bold
hi WarningMsg       guisp=NONE      guifg=#B58900   guibg=NONE      ctermfg=136     ctermbg=NONE gui=NONE           cterm=NONE
hi WildMenu         guisp=NONE      guifg=NONE      guibg=#93A1A1   ctermfg=NONE    ctermbg=245   gui=NONE           cterm=NONE
hi Comment          guisp=NONE      guifg=#93A1A1   guibg=NONE      ctermfg=245      ctermbg=NONE gui=NONE           cterm=NONE
hi Constant         guisp=NONE      guifg=#B58900   guibg=NONE      ctermfg=136     ctermbg=NONE gui=NONE           cterm=NONE
hi Identifier       guisp=NONE      guifg=#D33682   guibg=NONE      ctermfg=125     ctermbg=NONE gui=NONE           cterm=NONE
hi Statement        guisp=NONE      guifg=#D33682   guibg=NONE      ctermfg=125     ctermbg=NONE gui=NONE           cterm=NONE
hi PreProc          guisp=NONE      guifg=#6C71C4   guibg=NONE      ctermfg=61      ctermbg=NONE gui=NONE           cterm=NONE
hi Type             guisp=NONE      guifg=#6C71C4   guibg=NONE      ctermfg=61      ctermbg=NONE gui=NONE           cterm=NONE
hi Special          guisp=NONE      guifg=#2AA198   guibg=NONE      ctermfg=37      ctermbg=NONE gui=NONE           cterm=NONE
hi Underlined       guisp=NONE      guifg=#657B83   guibg=#FDF6E3   ctermfg=241     ctermbg=230  gui=underline      cterm=underline
hi Error            guisp=NONE      guifg=#DC322F   guibg=NONE      ctermfg=160     ctermbg=NONE gui=NONE           cterm=NONE
hi Todo             guisp=NONE      guifg=#657B83   guibg=#CB4B16   ctermfg=241     ctermbg=166  gui=bold           cterm=bold

hi String           guisp=NONE      guifg=#859900   guibg=NONE      ctermfg=64      ctermbg=NONE gui=NONE           cterm=NONE
hi Character        guisp=NONE      guifg=#2AA198   guibg=NONE      ctermfg=37      ctermbg=NONE gui=NONE           cterm=NONE
hi Number           guisp=NONE      guifg=#B58900   guibg=NONE      ctermfg=136     ctermbg=NONE gui=NONE           cterm=NONE
hi Boolean          guisp=NONE      guifg=#B58900   guibg=NONE      ctermfg=136     ctermbg=NONE gui=NONE           cterm=NONE
hi Float            guisp=NONE      guifg=#B58900   guibg=NONE      ctermfg=136     ctermbg=NONE gui=NONE           cterm=NONE
hi Function         guisp=NONE      guifg=#6C71C4   guibg=NONE      ctermfg=61      ctermbg=NONE gui=NONE           cterm=NONE
hi Conditional      guisp=NONE      guifg=#DC322F   guibg=NONE      ctermfg=160     ctermbg=NONE gui=NONE           cterm=NONE
hi Repeat           guisp=NONE      guifg=#DC322F   guibg=NONE      ctermfg=160     ctermbg=NONE gui=NONE           cterm=NONE
hi Label            guisp=NONE      guifg=#B58900   guibg=NONE      ctermfg=136     ctermbg=NONE gui=NONE           cterm=NONE
hi Operator         guisp=NONE      guifg=#2AA198   guibg=NONE      ctermfg=37      ctermbg=NONE gui=NONE           cterm=NONE
hi Keyword          guisp=NONE      guifg=#D33682   guibg=NONE      ctermfg=125     ctermbg=NONE gui=NONE           cterm=NONE
hi Include          guisp=NONE      guifg=#D33682   guibg=NONE      ctermfg=125     ctermbg=NONE gui=NONE           cterm=NONE
hi StorageClass     guisp=NONE      guifg=#CB4B16   guibg=NONE      ctermfg=166     ctermbg=NONE gui=NONE           cterm=NONE
hi Structure        guisp=NONE      guifg=#CB4B16   guibg=NONE      ctermfg=166     ctermbg=NONE gui=NONE           cterm=NONE
hi Typedef          guisp=NONE      guifg=#CB4B16   guibg=NONE      ctermfg=166     ctermbg=NONE gui=NONE           cterm=NONE
hi debugPC          guisp=NONE      guifg=NONE      guibg=#93A1A1   ctermfg=166     ctermbg=NONE gui=NONE           cterm=NONE
hi debugBreakpoint  guisp=NONE      guifg=#93A1A1   guibg=#FDF6E3   ctermfg=166     ctermbg=NONE gui=NONE           cterm=NONE

hi link Define PreProc
hi link Macro PreProc
hi link PreCondit PreProc
hi link SpecialChar Special
hi link Tag Special
hi link Delimiter Special
hi link SpecialComment Special
hi link Debug Special
hi link Exception Error
hi link StatusLineTerm StatusLine
hi link StatusLineTermNC StatusLineNC
hi link Terminal Normal
hi link Ignore Comment
