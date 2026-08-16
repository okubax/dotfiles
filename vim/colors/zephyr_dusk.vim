" Name: zephyr_dusk.vim
" Zephyr: a dim mid-tone colorscheme between Zephyr Light and Zephyr Dark.
" See ~/dotfiles/swaywm/zephyr/README.md and dusk/palette.md for the
" full palette and where each value comes from.

set background=dark
hi clear

if exists('syntax on')
    syntax reset
endif

let g:colors_name='zephyr_dusk'
set t_Co=256

" bg          = "#262B2E"  (interpolated, dim slate)
" bg_alt      = "#313639"  (interpolated)
" bg_panel    = "#383D40"  (interpolated)
" bg_panel_alt= "#454B4F"  (interpolated)
" fg          = "#EDEFF1"  (interpolated, softer than Dark's #FCFCFC)
" fg_muted    = "#A9AFB4"  (interpolated)
" border      = "#6B7278"  (interpolated)
" accent      = "#3DAEE9"  (Breeze accent blue, unchanged)
" link        = "#4FB3E8"  (interpolated between Light/Dark link, brightened)
" red/green/yellow/purple/cyan unchanged from light/dark — see palette.md

hi Normal           guisp=NONE      guifg=#EDEFF1   guibg=#262B2E   ctermfg=255     ctermbg=235  gui=NONE           cterm=NONE
hi Visual           guisp=NONE      guifg=NONE      guibg=#2E5D7D   ctermfg=NONE    ctermbg=24   gui=bold           cterm=bold

hi Conceal          guisp=NONE      guifg=#A9AFB4   guibg=NONE      ctermfg=249     ctermbg=NONE gui=NONE           cterm=NONE
hi ColorColumn      guisp=NONE      guifg=NONE      guibg=#454B4F   ctermfg=NONE    ctermbg=238  gui=NONE           cterm=NONE
hi Cursor           guisp=NONE      guifg=#262B2E   guibg=#3DAEE9   ctermfg=235     ctermbg=74   gui=NONE           cterm=NONE
hi lCursor          guisp=NONE      guifg=#262B2E   guibg=#3DAEE9   ctermfg=235     ctermbg=74   gui=NONE           cterm=NONE
hi CursorIM         guisp=NONE      guifg=#262B2E   guibg=#3DAEE9   ctermfg=235     ctermbg=74   gui=NONE           cterm=NONE
hi CursorColumn     guisp=NONE      guifg=NONE      guibg=#313639   ctermfg=NONE    ctermbg=236  gui=NONE           cterm=NONE
hi CursorLine       guisp=NONE      guifg=NONE      guibg=#313639   ctermfg=NONE    ctermbg=236  gui=NONE           cterm=NONE
hi Directory        guisp=NONE      guifg=#4FB3E8   guibg=NONE      ctermfg=39      ctermbg=NONE gui=NONE           cterm=NONE
hi DiffAdd          guisp=NONE      guifg=#262B2E   guibg=#27AE60   ctermfg=235     ctermbg=35   gui=NONE           cterm=NONE
hi DiffChange       guisp=NONE      guifg=#262B2E   guibg=#F1C40F   ctermfg=235     ctermbg=220  gui=NONE           cterm=NONE
hi DiffDelete       guisp=NONE      guifg=#EDEFF1   guibg=#DA4453   ctermfg=255     ctermbg=167  gui=NONE           cterm=NONE
hi DiffText         guisp=NONE      guifg=#262B2E   guibg=#3DAEE9   ctermfg=235     ctermbg=74   gui=NONE           cterm=NONE
hi EndOfBuffer      guisp=NONE      guifg=NONE      guibg=NONE      ctermfg=NONE    ctermbg=NONE gui=NONE           cterm=NONE
hi ErrorMsg         guisp=NONE      guifg=#DA4453   guibg=NONE      ctermfg=167     ctermbg=NONE gui=bold,italic    cterm=bold,italic
hi VertSplit        guisp=NONE      guifg=#6B7278   guibg=NONE      ctermfg=244     ctermbg=NONE gui=NONE           cterm=NONE
hi Folded           guisp=NONE      guifg=#4FB3E8   guibg=#454B4F   ctermfg=39      ctermbg=238  gui=NONE           cterm=NONE
hi FoldColumn       guisp=NONE      guifg=#A9AFB4   guibg=#262B2E   ctermfg=249     ctermbg=235  gui=NONE           cterm=NONE
hi SignColumn       guisp=NONE      guifg=#6B7278   guibg=#262B2E   ctermfg=244     ctermbg=235  gui=NONE           cterm=NONE
hi IncSearch        guisp=NONE      guifg=#262B2E   guibg=#F1C40F   ctermfg=235     ctermbg=220  gui=NONE           cterm=NONE
hi CursorLineNR     guisp=NONE      guifg=#3DAEE9   guibg=NONE      ctermfg=74      ctermbg=NONE gui=NONE           cterm=NONE
hi LineNr           guisp=NONE      guifg=#6B7278   guibg=NONE      ctermfg=244     ctermbg=NONE gui=NONE           cterm=NONE
hi MatchParen       guisp=NONE      guifg=#F67400   guibg=NONE      ctermfg=208     ctermbg=NONE gui=bold           cterm=bold
hi ModeMsg          guisp=NONE      guifg=#EDEFF1   guibg=NONE      ctermfg=255     ctermbg=NONE gui=bold           cterm=bold
hi MoreMsg          guisp=NONE      guifg=#4FB3E8   guibg=NONE      ctermfg=39      ctermbg=NONE gui=NONE           cterm=NONE
hi NonText          guisp=NONE      guifg=#6B7278   guibg=NONE      ctermfg=244     ctermbg=NONE gui=NONE           cterm=NONE
hi Pmenu            guisp=NONE      guifg=#EDEFF1   guibg=#454B4F   ctermfg=255     ctermbg=238  gui=NONE           cterm=NONE
hi PmenuSel         guisp=NONE      guifg=#262B2E   guibg=#3DAEE9   ctermfg=235     ctermbg=74   gui=bold           cterm=bold
hi PmenuSbar        guisp=NONE      guifg=NONE      guibg=#454B4F   ctermfg=NONE    ctermbg=238  gui=NONE           cterm=NONE
hi PmenuThumb       guisp=NONE      guifg=NONE      guibg=#A9AFB4   ctermfg=NONE    ctermbg=249  gui=NONE           cterm=NONE
hi Question         guisp=NONE      guifg=#4FB3E8   guibg=NONE      ctermfg=39      ctermbg=NONE gui=NONE           cterm=NONE
hi QuickFixLine     guisp=NONE      guifg=NONE      guibg=#454B4F   ctermfg=NONE    ctermbg=238  gui=bold           cterm=bold
hi Search           guisp=NONE      guifg=#262B2E   guibg=#2E5D7D   ctermfg=235     ctermbg=24   gui=bold           cterm=bold
hi SpecialKey       guisp=NONE      guifg=#A9AFB4   guibg=NONE      ctermfg=249     ctermbg=NONE gui=NONE           cterm=NONE
hi SpellBad         guisp=#DA4453   guifg=NONE      guibg=NONE      ctermfg=167     ctermbg=NONE gui=underline      cterm=underline
hi SpellCap         guisp=#F1C40F   guifg=NONE      guibg=NONE      ctermfg=220     ctermbg=NONE gui=underline      cterm=underline
hi SpellLocal       guisp=#4FB3E8   guifg=NONE      guibg=NONE      ctermfg=39      ctermbg=NONE gui=underline      cterm=underline
hi SpellRare        guisp=#27AE60   guifg=NONE      guibg=NONE      ctermfg=35      ctermbg=NONE gui=underline      cterm=underline
hi StatusLine       guisp=NONE      guifg=#EDEFF1   guibg=#454B4F   ctermfg=255     ctermbg=238  gui=NONE           cterm=NONE
hi StatusLineNC     guisp=NONE      guifg=#A9AFB4   guibg=#454B4F   ctermfg=249     ctermbg=238  gui=NONE           cterm=NONE
hi TabLine          guisp=NONE      guifg=#A9AFB4   guibg=#454B4F   ctermfg=249     ctermbg=238  gui=NONE           cterm=NONE
hi TabLineFill      guisp=NONE      guifg=NONE      guibg=#454B4F   ctermfg=NONE    ctermbg=238  gui=NONE           cterm=NONE
hi TabLineSel       guisp=NONE      guifg=#27AE60   guibg=#262B2E   ctermfg=35      ctermbg=235  gui=NONE           cterm=NONE
hi Title            guisp=NONE      guifg=#4FB3E8   guibg=NONE      ctermfg=39      ctermbg=NONE gui=bold           cterm=bold
hi VisualNOS        guisp=NONE      guifg=NONE      guibg=#2E5D7D   ctermfg=NONE    ctermbg=24   gui=bold           cterm=bold
hi WarningMsg       guisp=NONE      guifg=#F67400   guibg=NONE      ctermfg=208     ctermbg=NONE gui=NONE           cterm=NONE
hi WildMenu         guisp=NONE      guifg=NONE      guibg=#A9AFB4   ctermfg=NONE    ctermbg=249  gui=NONE           cterm=NONE
hi Comment          guisp=NONE      guifg=#A9AFB4   guibg=NONE      ctermfg=249     ctermbg=NONE gui=NONE           cterm=NONE
hi Constant         guisp=NONE      guifg=#F67400   guibg=NONE      ctermfg=208     ctermbg=NONE gui=NONE           cterm=NONE
hi Identifier       guisp=NONE      guifg=#9B59B6   guibg=NONE      ctermfg=133     ctermbg=NONE gui=NONE           cterm=NONE
hi Statement        guisp=NONE      guifg=#9B59B6   guibg=NONE      ctermfg=133     ctermbg=NONE gui=NONE           cterm=NONE
hi PreProc          guisp=NONE      guifg=#4FB3E8   guibg=NONE      ctermfg=39      ctermbg=NONE gui=NONE           cterm=NONE
hi Type             guisp=NONE      guifg=#4FB3E8   guibg=NONE      ctermfg=39      ctermbg=NONE gui=NONE           cterm=NONE
hi Special          guisp=NONE      guifg=#1ABC9C   guibg=NONE      ctermfg=37      ctermbg=NONE gui=NONE           cterm=NONE
hi Underlined       guisp=NONE      guifg=#EDEFF1   guibg=#262B2E   ctermfg=255     ctermbg=235  gui=underline      cterm=underline
hi Error            guisp=NONE      guifg=#DA4453   guibg=NONE      ctermfg=167     ctermbg=NONE gui=NONE           cterm=NONE
hi Todo             guisp=NONE      guifg=#262B2E   guibg=#F1C40F   ctermfg=235     ctermbg=220  gui=bold           cterm=bold

hi String           guisp=NONE      guifg=#27AE60   guibg=NONE      ctermfg=35      ctermbg=NONE gui=NONE           cterm=NONE
hi Character        guisp=NONE      guifg=#1ABC9C   guibg=NONE      ctermfg=37      ctermbg=NONE gui=NONE           cterm=NONE
hi Number           guisp=NONE      guifg=#F67400   guibg=NONE      ctermfg=208     ctermbg=NONE gui=NONE           cterm=NONE
hi Boolean          guisp=NONE      guifg=#F67400   guibg=NONE      ctermfg=208     ctermbg=NONE gui=NONE           cterm=NONE
hi Float            guisp=NONE      guifg=#F67400   guibg=NONE      ctermfg=208     ctermbg=NONE gui=NONE           cterm=NONE
hi Function         guisp=NONE      guifg=#4FB3E8   guibg=NONE      ctermfg=39      ctermbg=NONE gui=NONE           cterm=NONE
hi Conditional      guisp=NONE      guifg=#DA4453   guibg=NONE      ctermfg=167     ctermbg=NONE gui=NONE           cterm=NONE
hi Repeat           guisp=NONE      guifg=#DA4453   guibg=NONE      ctermfg=167     ctermbg=NONE gui=NONE           cterm=NONE
hi Label            guisp=NONE      guifg=#F67400   guibg=NONE      ctermfg=208     ctermbg=NONE gui=NONE           cterm=NONE
hi Operator         guisp=NONE      guifg=#1ABC9C   guibg=NONE      ctermfg=37      ctermbg=NONE gui=NONE           cterm=NONE
hi Keyword          guisp=NONE      guifg=#9B59B6   guibg=NONE      ctermfg=133     ctermbg=NONE gui=NONE           cterm=NONE
hi Include          guisp=NONE      guifg=#9B59B6   guibg=NONE      ctermfg=133     ctermbg=NONE gui=NONE           cterm=NONE
hi StorageClass     guisp=NONE      guifg=#F1C40F   guibg=NONE      ctermfg=220     ctermbg=NONE gui=NONE           cterm=NONE
hi Structure        guisp=NONE      guifg=#F1C40F   guibg=NONE      ctermfg=220     ctermbg=NONE gui=NONE           cterm=NONE
hi Typedef          guisp=NONE      guifg=#F1C40F   guibg=NONE      ctermfg=220     ctermbg=NONE gui=NONE           cterm=NONE
hi debugPC          guisp=NONE      guifg=NONE      guibg=#454B4F   ctermfg=220     ctermbg=NONE gui=NONE           cterm=NONE
hi debugBreakpoint  guisp=NONE      guifg=#A9AFB4   guibg=#262B2E   ctermfg=220     ctermbg=NONE gui=NONE           cterm=NONE

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
