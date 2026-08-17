" Name: nord_light.vim
" Nord Light: no official Nord light variant exists — Snow Storm and Polar
" Night swap roles (background <-> text) instead. See
" ~/dotfiles/swaywm/nord/README.md and light/palette.md for the full
" palette and where each value comes from.

set background=light
hi clear

if exists('syntax on')
    syntax reset
endif

let g:colors_name='nord_light'
set t_Co=256

" bg          = "#ECEFF4"  (Nord nord6, Snow Storm, inverted role)
" bg_alt      = "#E5E9F0"  (Nord nord5, Snow Storm, inverted role)
" bg_panel    = "#D8DEE9"  (Nord nord4, Snow Storm, inverted role)
" bg_panel_alt= "#929AA9"  (interpolated, nord4->nord3)
" fg          = "#2E3440"  (Nord nord0, Polar Night, inverted role)
" fg_muted    = "#4C566A"  (Nord nord3, Polar Night, inverted role)
" border      = "#4C566A"  (Nord nord3, reused)
" accent      = "#88C0D0"  (Nord nord8, Frost, unchanged all variants)
" link        = "#5E81AC"  (Nord nord10, Frost, light-only weight)
" red         = "#BF616A"  (Nord nord11, Aurora)
" green       = "#A3BE8C"  (Nord nord14, Aurora)
" yellow      = "#EBCB8B"  (Nord nord13, Aurora)
" purple      = "#B48EAD"  (Nord nord15, Aurora)
" cyan        = "#8FBCBB"  (Nord nord7, Frost)
" orange (2nd accent) = "#D08770" (Nord nord12, Aurora) — unchanged across variants

hi Normal           guisp=NONE      guifg=#2E3440   guibg=#ECEFF4   ctermfg=236     ctermbg=255  gui=NONE           cterm=NONE
hi Visual           guisp=NONE      guifg=NONE      guibg=#C3DEE4   ctermfg=NONE    ctermbg=153  gui=bold           cterm=bold

hi Conceal          guisp=NONE      guifg=#4C566A   guibg=NONE      ctermfg=239      ctermbg=NONE gui=NONE           cterm=NONE
hi ColorColumn      guisp=NONE      guifg=NONE      guibg=#929AA9   ctermfg=NONE    ctermbg=248  gui=NONE           cterm=NONE
hi Cursor           guisp=NONE      guifg=#ECEFF4   guibg=#88C0D0   ctermfg=255     ctermbg=110   gui=NONE           cterm=NONE
hi lCursor          guisp=NONE      guifg=#ECEFF4   guibg=#88C0D0   ctermfg=255     ctermbg=110   gui=NONE           cterm=NONE
hi CursorIM         guisp=NONE      guifg=#ECEFF4   guibg=#88C0D0   ctermfg=255     ctermbg=110   gui=NONE           cterm=NONE
hi CursorColumn     guisp=NONE      guifg=NONE      guibg=#E5E9F0   ctermfg=NONE    ctermbg=254  gui=NONE           cterm=NONE
hi CursorLine       guisp=NONE      guifg=NONE      guibg=#E5E9F0   ctermfg=NONE    ctermbg=254  gui=NONE           cterm=NONE
hi Directory        guisp=NONE      guifg=#5E81AC   guibg=NONE      ctermfg=67      ctermbg=NONE gui=NONE           cterm=NONE
hi DiffAdd          guisp=NONE      guifg=#ECEFF4   guibg=#A3BE8C   ctermfg=255     ctermbg=150   gui=NONE           cterm=NONE
hi DiffChange       guisp=NONE      guifg=#2E3440   guibg=#D08770   ctermfg=236     ctermbg=173  gui=NONE           cterm=NONE
hi DiffDelete       guisp=NONE      guifg=#ECEFF4   guibg=#BF616A   ctermfg=255     ctermbg=131  gui=NONE           cterm=NONE
hi DiffText         guisp=NONE      guifg=#ECEFF4   guibg=#88C0D0   ctermfg=255     ctermbg=110   gui=NONE           cterm=NONE
hi EndOfBuffer      guisp=NONE      guifg=NONE      guibg=NONE      ctermfg=NONE    ctermbg=NONE gui=NONE           cterm=NONE
hi ErrorMsg         guisp=NONE      guifg=#BF616A   guibg=NONE      ctermfg=131     ctermbg=NONE gui=bold,italic    cterm=bold,italic
hi VertSplit        guisp=NONE      guifg=#4C566A   guibg=NONE      ctermfg=239     ctermbg=NONE gui=NONE           cterm=NONE
hi Folded           guisp=NONE      guifg=#5E81AC   guibg=#929AA9   ctermfg=67      ctermbg=248  gui=NONE           cterm=NONE
hi FoldColumn       guisp=NONE      guifg=#4C566A   guibg=#ECEFF4   ctermfg=239      ctermbg=255  gui=NONE           cterm=NONE
hi SignColumn       guisp=NONE      guifg=#4C566A   guibg=#ECEFF4   ctermfg=239     ctermbg=255  gui=NONE           cterm=NONE
hi IncSearch        guisp=NONE      guifg=#2E3440   guibg=#D08770   ctermfg=236     ctermbg=173  gui=NONE           cterm=NONE
hi CursorLineNR     guisp=NONE      guifg=#88C0D0   guibg=NONE      ctermfg=110      ctermbg=NONE gui=NONE           cterm=NONE
hi LineNr           guisp=NONE      guifg=#4C566A   guibg=NONE      ctermfg=239     ctermbg=NONE gui=NONE           cterm=NONE
hi MatchParen       guisp=NONE      guifg=#EBCB8B   guibg=NONE      ctermfg=222     ctermbg=NONE gui=bold           cterm=bold
hi ModeMsg          guisp=NONE      guifg=#2E3440   guibg=NONE      ctermfg=236     ctermbg=NONE gui=bold           cterm=bold
hi MoreMsg          guisp=NONE      guifg=#5E81AC   guibg=NONE      ctermfg=67      ctermbg=NONE gui=NONE           cterm=NONE
hi NonText          guisp=NONE      guifg=#4C566A   guibg=NONE      ctermfg=239     ctermbg=NONE gui=NONE           cterm=NONE
hi Pmenu            guisp=NONE      guifg=#2E3440   guibg=#929AA9   ctermfg=236     ctermbg=248  gui=NONE           cterm=NONE
hi PmenuSel         guisp=NONE      guifg=#ECEFF4   guibg=#88C0D0   ctermfg=255     ctermbg=110   gui=bold           cterm=bold
hi PmenuSbar        guisp=NONE      guifg=NONE      guibg=#929AA9   ctermfg=NONE    ctermbg=248  gui=NONE           cterm=NONE
hi PmenuThumb       guisp=NONE      guifg=NONE      guibg=#4C566A   ctermfg=NONE    ctermbg=239   gui=NONE           cterm=NONE
hi Question         guisp=NONE      guifg=#5E81AC   guibg=NONE      ctermfg=67      ctermbg=NONE gui=NONE           cterm=NONE
hi QuickFixLine     guisp=NONE      guifg=NONE      guibg=#929AA9   ctermfg=NONE    ctermbg=248  gui=bold           cterm=bold
hi Search           guisp=NONE      guifg=#2E3440   guibg=#C3DEE4   ctermfg=236     ctermbg=153  gui=bold           cterm=bold
hi SpecialKey       guisp=NONE      guifg=#4C566A   guibg=NONE      ctermfg=239      ctermbg=NONE gui=NONE           cterm=NONE
hi SpellBad         guisp=#BF616A   guifg=NONE      guibg=NONE      ctermfg=131     ctermbg=NONE gui=underline      cterm=underline
hi SpellCap         guisp=#D08770   guifg=NONE      guibg=NONE      ctermfg=173     ctermbg=NONE gui=underline      cterm=underline
hi SpellLocal       guisp=#5E81AC   guifg=NONE      guibg=NONE      ctermfg=67      ctermbg=NONE gui=underline      cterm=underline
hi SpellRare        guisp=#A3BE8C   guifg=NONE      guibg=NONE      ctermfg=150      ctermbg=NONE gui=underline      cterm=underline
hi StatusLine       guisp=NONE      guifg=#2E3440   guibg=#929AA9   ctermfg=236     ctermbg=248  gui=NONE           cterm=NONE
hi StatusLineNC     guisp=NONE      guifg=#4C566A   guibg=#929AA9   ctermfg=239      ctermbg=248  gui=NONE           cterm=NONE
hi TabLine          guisp=NONE      guifg=#4C566A   guibg=#929AA9   ctermfg=239      ctermbg=248  gui=NONE           cterm=NONE
hi TabLineFill      guisp=NONE      guifg=NONE      guibg=#929AA9   ctermfg=NONE    ctermbg=248  gui=NONE           cterm=NONE
hi TabLineSel       guisp=NONE      guifg=#A3BE8C   guibg=#ECEFF4   ctermfg=150      ctermbg=255  gui=NONE           cterm=NONE
hi Title            guisp=NONE      guifg=#5E81AC   guibg=NONE      ctermfg=67      ctermbg=NONE gui=bold           cterm=bold
hi VisualNOS        guisp=NONE      guifg=NONE      guibg=#C3DEE4   ctermfg=NONE    ctermbg=153  gui=bold           cterm=bold
hi WarningMsg       guisp=NONE      guifg=#EBCB8B   guibg=NONE      ctermfg=222     ctermbg=NONE gui=NONE           cterm=NONE
hi WildMenu         guisp=NONE      guifg=NONE      guibg=#4C566A   ctermfg=NONE    ctermbg=239   gui=NONE           cterm=NONE
hi Comment          guisp=NONE      guifg=#4C566A   guibg=NONE      ctermfg=239      ctermbg=NONE gui=NONE           cterm=NONE
hi Constant         guisp=NONE      guifg=#EBCB8B   guibg=NONE      ctermfg=222     ctermbg=NONE gui=NONE           cterm=NONE
hi Identifier       guisp=NONE      guifg=#B48EAD   guibg=NONE      ctermfg=139     ctermbg=NONE gui=NONE           cterm=NONE
hi Statement        guisp=NONE      guifg=#B48EAD   guibg=NONE      ctermfg=139     ctermbg=NONE gui=NONE           cterm=NONE
hi PreProc          guisp=NONE      guifg=#5E81AC   guibg=NONE      ctermfg=67      ctermbg=NONE gui=NONE           cterm=NONE
hi Type             guisp=NONE      guifg=#5E81AC   guibg=NONE      ctermfg=67      ctermbg=NONE gui=NONE           cterm=NONE
hi Special          guisp=NONE      guifg=#8FBCBB   guibg=NONE      ctermfg=108      ctermbg=NONE gui=NONE           cterm=NONE
hi Underlined       guisp=NONE      guifg=#2E3440   guibg=#ECEFF4   ctermfg=236     ctermbg=255  gui=underline      cterm=underline
hi Error            guisp=NONE      guifg=#BF616A   guibg=NONE      ctermfg=131     ctermbg=NONE gui=NONE           cterm=NONE
hi Todo             guisp=NONE      guifg=#2E3440   guibg=#D08770   ctermfg=236     ctermbg=173  gui=bold           cterm=bold

hi String           guisp=NONE      guifg=#A3BE8C   guibg=NONE      ctermfg=150      ctermbg=NONE gui=NONE           cterm=NONE
hi Character        guisp=NONE      guifg=#8FBCBB   guibg=NONE      ctermfg=108      ctermbg=NONE gui=NONE           cterm=NONE
hi Number           guisp=NONE      guifg=#EBCB8B   guibg=NONE      ctermfg=222     ctermbg=NONE gui=NONE           cterm=NONE
hi Boolean          guisp=NONE      guifg=#EBCB8B   guibg=NONE      ctermfg=222     ctermbg=NONE gui=NONE           cterm=NONE
hi Float            guisp=NONE      guifg=#EBCB8B   guibg=NONE      ctermfg=222     ctermbg=NONE gui=NONE           cterm=NONE
hi Function         guisp=NONE      guifg=#5E81AC   guibg=NONE      ctermfg=67      ctermbg=NONE gui=NONE           cterm=NONE
hi Conditional      guisp=NONE      guifg=#BF616A   guibg=NONE      ctermfg=131     ctermbg=NONE gui=NONE           cterm=NONE
hi Repeat           guisp=NONE      guifg=#BF616A   guibg=NONE      ctermfg=131     ctermbg=NONE gui=NONE           cterm=NONE
hi Label            guisp=NONE      guifg=#EBCB8B   guibg=NONE      ctermfg=222     ctermbg=NONE gui=NONE           cterm=NONE
hi Operator         guisp=NONE      guifg=#8FBCBB   guibg=NONE      ctermfg=108      ctermbg=NONE gui=NONE           cterm=NONE
hi Keyword          guisp=NONE      guifg=#B48EAD   guibg=NONE      ctermfg=139     ctermbg=NONE gui=NONE           cterm=NONE
hi Include          guisp=NONE      guifg=#B48EAD   guibg=NONE      ctermfg=139     ctermbg=NONE gui=NONE           cterm=NONE
hi StorageClass     guisp=NONE      guifg=#D08770   guibg=NONE      ctermfg=173     ctermbg=NONE gui=NONE           cterm=NONE
hi Structure        guisp=NONE      guifg=#D08770   guibg=NONE      ctermfg=173     ctermbg=NONE gui=NONE           cterm=NONE
hi Typedef          guisp=NONE      guifg=#D08770   guibg=NONE      ctermfg=173     ctermbg=NONE gui=NONE           cterm=NONE
hi debugPC          guisp=NONE      guifg=NONE      guibg=#929AA9   ctermfg=173     ctermbg=NONE gui=NONE           cterm=NONE
hi debugBreakpoint  guisp=NONE      guifg=#4C566A   guibg=#ECEFF4   ctermfg=173     ctermbg=NONE gui=NONE           cterm=NONE

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
