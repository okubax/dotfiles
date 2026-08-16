" Name: zephyr_dark.vim
" Zephyr: a Breeze Dark-matched colorscheme. See
" ~/dotfiles/swaywm/zephyr/README.md and dark/palette.md for the
" full palette and where each value comes from.

set background=dark
hi clear

if exists('syntax on')
    syntax reset
endif

let g:colors_name='zephyr_dark'
set t_Co=256

" bg          = "#141618"  (Breeze View bg)
" bg_alt      = "#1D1F22"  (Breeze View bg alt)
" bg_panel    = "#202326"  (Breeze Window bg)
" bg_panel_alt= "#292C30"  (Breeze Window/Header/Button bg alt)
" fg          = "#FCFCFC"  (Breeze View fg)
" fg_muted    = "#A1A9B1"  (Breeze View fg inactive)
" border      = "#3B4045"  (interpolated)
" accent      = "#3DAEE9"  (Breeze accent blue, unchanged from light)
" link        = "#1D99F3"  (Breeze link, dark variant)
" red/green/yellow/purple/cyan unchanged from light — see palette.md

hi Normal           guisp=NONE      guifg=#FCFCFC   guibg=#141618   ctermfg=231     ctermbg=233  gui=NONE           cterm=NONE
hi Visual           guisp=NONE      guifg=NONE      guibg=#1E5774   ctermfg=NONE    ctermbg=24   gui=bold           cterm=bold

hi Conceal          guisp=NONE      guifg=#A1A9B1   guibg=NONE      ctermfg=248     ctermbg=NONE gui=NONE           cterm=NONE
hi ColorColumn      guisp=NONE      guifg=NONE      guibg=#292C30   ctermfg=NONE    ctermbg=236  gui=NONE           cterm=NONE
hi Cursor           guisp=NONE      guifg=#141618   guibg=#3DAEE9   ctermfg=233     ctermbg=74   gui=NONE           cterm=NONE
hi lCursor          guisp=NONE      guifg=#141618   guibg=#3DAEE9   ctermfg=233     ctermbg=74   gui=NONE           cterm=NONE
hi CursorIM         guisp=NONE      guifg=#141618   guibg=#3DAEE9   ctermfg=233     ctermbg=74   gui=NONE           cterm=NONE
hi CursorColumn     guisp=NONE      guifg=NONE      guibg=#1D1F22   ctermfg=NONE    ctermbg=234  gui=NONE           cterm=NONE
hi CursorLine       guisp=NONE      guifg=NONE      guibg=#1D1F22   ctermfg=NONE    ctermbg=234  gui=NONE           cterm=NONE
hi Directory        guisp=NONE      guifg=#1D99F3   guibg=NONE      ctermfg=33      ctermbg=NONE gui=NONE           cterm=NONE
hi DiffAdd          guisp=NONE      guifg=#141618   guibg=#27AE60   ctermfg=233     ctermbg=35   gui=NONE           cterm=NONE
hi DiffChange       guisp=NONE      guifg=#141618   guibg=#F1C40F   ctermfg=233     ctermbg=220  gui=NONE           cterm=NONE
hi DiffDelete       guisp=NONE      guifg=#FCFCFC   guibg=#DA4453   ctermfg=231     ctermbg=167  gui=NONE           cterm=NONE
hi DiffText         guisp=NONE      guifg=#141618   guibg=#3DAEE9   ctermfg=233     ctermbg=74   gui=NONE           cterm=NONE
hi EndOfBuffer      guisp=NONE      guifg=NONE      guibg=NONE      ctermfg=NONE    ctermbg=NONE gui=NONE           cterm=NONE
hi ErrorMsg         guisp=NONE      guifg=#DA4453   guibg=NONE      ctermfg=167     ctermbg=NONE gui=bold,italic    cterm=bold,italic
hi VertSplit        guisp=NONE      guifg=#3B4045   guibg=NONE      ctermfg=238     ctermbg=NONE gui=NONE           cterm=NONE
hi Folded           guisp=NONE      guifg=#1D99F3   guibg=#292C30   ctermfg=33      ctermbg=236  gui=NONE           cterm=NONE
hi FoldColumn       guisp=NONE      guifg=#A1A9B1   guibg=#141618   ctermfg=248     ctermbg=233  gui=NONE           cterm=NONE
hi SignColumn       guisp=NONE      guifg=#3B4045   guibg=#141618   ctermfg=238     ctermbg=233  gui=NONE           cterm=NONE
hi IncSearch        guisp=NONE      guifg=#141618   guibg=#F1C40F   ctermfg=233     ctermbg=220  gui=NONE           cterm=NONE
hi CursorLineNR     guisp=NONE      guifg=#3DAEE9   guibg=NONE      ctermfg=74      ctermbg=NONE gui=NONE           cterm=NONE
hi LineNr           guisp=NONE      guifg=#3B4045   guibg=NONE      ctermfg=238     ctermbg=NONE gui=NONE           cterm=NONE
hi MatchParen       guisp=NONE      guifg=#F67400   guibg=NONE      ctermfg=208     ctermbg=NONE gui=bold           cterm=bold
hi ModeMsg          guisp=NONE      guifg=#FCFCFC   guibg=NONE      ctermfg=231     ctermbg=NONE gui=bold           cterm=bold
hi MoreMsg          guisp=NONE      guifg=#1D99F3   guibg=NONE      ctermfg=33      ctermbg=NONE gui=NONE           cterm=NONE
hi NonText          guisp=NONE      guifg=#3B4045   guibg=NONE      ctermfg=238     ctermbg=NONE gui=NONE           cterm=NONE
hi Pmenu            guisp=NONE      guifg=#FCFCFC   guibg=#292C30   ctermfg=231     ctermbg=236  gui=NONE           cterm=NONE
hi PmenuSel         guisp=NONE      guifg=#141618   guibg=#3DAEE9   ctermfg=233     ctermbg=74   gui=bold           cterm=bold
hi PmenuSbar        guisp=NONE      guifg=NONE      guibg=#292C30   ctermfg=NONE    ctermbg=236  gui=NONE           cterm=NONE
hi PmenuThumb       guisp=NONE      guifg=NONE      guibg=#A1A9B1   ctermfg=NONE    ctermbg=248  gui=NONE           cterm=NONE
hi Question         guisp=NONE      guifg=#1D99F3   guibg=NONE      ctermfg=33      ctermbg=NONE gui=NONE           cterm=NONE
hi QuickFixLine     guisp=NONE      guifg=NONE      guibg=#292C30   ctermfg=NONE    ctermbg=236  gui=bold           cterm=bold
hi Search           guisp=NONE      guifg=#141618   guibg=#1E5774   ctermfg=233     ctermbg=24   gui=bold           cterm=bold
hi SpecialKey       guisp=NONE      guifg=#A1A9B1   guibg=NONE      ctermfg=248     ctermbg=NONE gui=NONE           cterm=NONE
hi SpellBad         guisp=#DA4453   guifg=NONE      guibg=NONE      ctermfg=167     ctermbg=NONE gui=underline      cterm=underline
hi SpellCap         guisp=#F1C40F   guifg=NONE      guibg=NONE      ctermfg=220     ctermbg=NONE gui=underline      cterm=underline
hi SpellLocal       guisp=#1D99F3   guifg=NONE      guibg=NONE      ctermfg=33      ctermbg=NONE gui=underline      cterm=underline
hi SpellRare        guisp=#27AE60   guifg=NONE      guibg=NONE      ctermfg=35      ctermbg=NONE gui=underline      cterm=underline
hi StatusLine       guisp=NONE      guifg=#FCFCFC   guibg=#292C30   ctermfg=231     ctermbg=236  gui=NONE           cterm=NONE
hi StatusLineNC     guisp=NONE      guifg=#A1A9B1   guibg=#292C30   ctermfg=248     ctermbg=236  gui=NONE           cterm=NONE
hi TabLine          guisp=NONE      guifg=#A1A9B1   guibg=#292C30   ctermfg=248     ctermbg=236  gui=NONE           cterm=NONE
hi TabLineFill      guisp=NONE      guifg=NONE      guibg=#292C30   ctermfg=NONE    ctermbg=236  gui=NONE           cterm=NONE
hi TabLineSel       guisp=NONE      guifg=#27AE60   guibg=#141618   ctermfg=35      ctermbg=233  gui=NONE           cterm=NONE
hi Title            guisp=NONE      guifg=#1D99F3   guibg=NONE      ctermfg=33      ctermbg=NONE gui=bold           cterm=bold
hi VisualNOS        guisp=NONE      guifg=NONE      guibg=#1E5774   ctermfg=NONE    ctermbg=24   gui=bold           cterm=bold
hi WarningMsg       guisp=NONE      guifg=#F67400   guibg=NONE      ctermfg=208     ctermbg=NONE gui=NONE           cterm=NONE
hi WildMenu         guisp=NONE      guifg=NONE      guibg=#A1A9B1   ctermfg=NONE    ctermbg=248  gui=NONE           cterm=NONE
hi Comment          guisp=NONE      guifg=#A1A9B1   guibg=NONE      ctermfg=248     ctermbg=NONE gui=NONE           cterm=NONE
hi Constant         guisp=NONE      guifg=#F67400   guibg=NONE      ctermfg=208     ctermbg=NONE gui=NONE           cterm=NONE
hi Identifier       guisp=NONE      guifg=#9B59B6   guibg=NONE      ctermfg=133     ctermbg=NONE gui=NONE           cterm=NONE
hi Statement        guisp=NONE      guifg=#9B59B6   guibg=NONE      ctermfg=133     ctermbg=NONE gui=NONE           cterm=NONE
hi PreProc          guisp=NONE      guifg=#1D99F3   guibg=NONE      ctermfg=33      ctermbg=NONE gui=NONE           cterm=NONE
hi Type             guisp=NONE      guifg=#1D99F3   guibg=NONE      ctermfg=33      ctermbg=NONE gui=NONE           cterm=NONE
hi Special          guisp=NONE      guifg=#1ABC9C   guibg=NONE      ctermfg=37      ctermbg=NONE gui=NONE           cterm=NONE
hi Underlined       guisp=NONE      guifg=#FCFCFC   guibg=#141618   ctermfg=231     ctermbg=233  gui=underline      cterm=underline
hi Error            guisp=NONE      guifg=#DA4453   guibg=NONE      ctermfg=167     ctermbg=NONE gui=NONE           cterm=NONE
hi Todo             guisp=NONE      guifg=#141618   guibg=#F1C40F   ctermfg=233     ctermbg=220  gui=bold           cterm=bold

hi String           guisp=NONE      guifg=#27AE60   guibg=NONE      ctermfg=35      ctermbg=NONE gui=NONE           cterm=NONE
hi Character        guisp=NONE      guifg=#1ABC9C   guibg=NONE      ctermfg=37      ctermbg=NONE gui=NONE           cterm=NONE
hi Number           guisp=NONE      guifg=#F67400   guibg=NONE      ctermfg=208     ctermbg=NONE gui=NONE           cterm=NONE
hi Boolean          guisp=NONE      guifg=#F67400   guibg=NONE      ctermfg=208     ctermbg=NONE gui=NONE           cterm=NONE
hi Float            guisp=NONE      guifg=#F67400   guibg=NONE      ctermfg=208     ctermbg=NONE gui=NONE           cterm=NONE
hi Function         guisp=NONE      guifg=#1D99F3   guibg=NONE      ctermfg=33      ctermbg=NONE gui=NONE           cterm=NONE
hi Conditional      guisp=NONE      guifg=#DA4453   guibg=NONE      ctermfg=167     ctermbg=NONE gui=NONE           cterm=NONE
hi Repeat           guisp=NONE      guifg=#DA4453   guibg=NONE      ctermfg=167     ctermbg=NONE gui=NONE           cterm=NONE
hi Label            guisp=NONE      guifg=#F67400   guibg=NONE      ctermfg=208     ctermbg=NONE gui=NONE           cterm=NONE
hi Operator         guisp=NONE      guifg=#1ABC9C   guibg=NONE      ctermfg=37      ctermbg=NONE gui=NONE           cterm=NONE
hi Keyword          guisp=NONE      guifg=#9B59B6   guibg=NONE      ctermfg=133     ctermbg=NONE gui=NONE           cterm=NONE
hi Include          guisp=NONE      guifg=#9B59B6   guibg=NONE      ctermfg=133     ctermbg=NONE gui=NONE           cterm=NONE
hi StorageClass     guisp=NONE      guifg=#F1C40F   guibg=NONE      ctermfg=220     ctermbg=NONE gui=NONE           cterm=NONE
hi Structure        guisp=NONE      guifg=#F1C40F   guibg=NONE      ctermfg=220     ctermbg=NONE gui=NONE           cterm=NONE
hi Typedef          guisp=NONE      guifg=#F1C40F   guibg=NONE      ctermfg=220     ctermbg=NONE gui=NONE           cterm=NONE
hi debugPC          guisp=NONE      guifg=NONE      guibg=#292C30   ctermfg=220     ctermbg=NONE gui=NONE           cterm=NONE
hi debugBreakpoint  guisp=NONE      guifg=#A1A9B1   guibg=#141618   ctermfg=220     ctermbg=NONE gui=NONE           cterm=NONE

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
