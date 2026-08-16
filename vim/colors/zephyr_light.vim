" Name: zephyr_light.vim
" Zephyr: a Breeze Light-matched colorscheme. See
" ~/dotfiles/swaywm/zephyr/README.md and light/palette.md for the
" full palette and where each value comes from.

set background=light
hi clear

if exists('syntax on')
    syntax reset
endif

let g:colors_name='zephyr_light'
set t_Co=256

" bg          = "#FCFCFC"  (Breeze Button bg)
" bg_alt      = "#F7F7F7"  (Breeze View bg alt)
" bg_panel    = "#EFF0F1"  (Breeze Window bg)
" bg_panel_alt= "#E3E5E7"  (Breeze Window bg alt)
" fg          = "#232629"  (Breeze View fg)
" fg_muted    = "#707D8A"  (Breeze View fg inactive)
" border      = "#C7CBCF"  (interpolated)
" accent      = "#3DAEE9"  (Breeze accent blue)
" link        = "#2980B9"  (Breeze link)
" red         = "#DA4453"  (Breeze negative)
" green       = "#27AE60"  (Breeze positive)
" yellow      = "#F67400"  (Breeze neutral/orange)
" purple      = "#9B59B6"  (Breeze visited)
" cyan        = "#1ABC9C"  (Flat UI Turquoise)
" red_bright  = "#C0392B" | green_bright = "#2ECC71"
" yellow_bright = "#F1C40F" | purple_bright = "#8E44AD" | cyan_bright = "#16A085"

hi Normal           guisp=NONE      guifg=#232629   guibg=#FCFCFC   ctermfg=235     ctermbg=231  gui=NONE           cterm=NONE
hi Visual           guisp=NONE      guifg=NONE      guibg=#A3D4FA   ctermfg=NONE    ctermbg=153  gui=bold           cterm=bold

hi Conceal          guisp=NONE      guifg=#707D8A   guibg=NONE      ctermfg=66      ctermbg=NONE gui=NONE           cterm=NONE
hi ColorColumn      guisp=NONE      guifg=NONE      guibg=#E3E5E7   ctermfg=NONE    ctermbg=254  gui=NONE           cterm=NONE
hi Cursor           guisp=NONE      guifg=#FCFCFC   guibg=#3DAEE9   ctermfg=231     ctermbg=74   gui=NONE           cterm=NONE
hi lCursor          guisp=NONE      guifg=#FCFCFC   guibg=#3DAEE9   ctermfg=231     ctermbg=74   gui=NONE           cterm=NONE
hi CursorIM         guisp=NONE      guifg=#FCFCFC   guibg=#3DAEE9   ctermfg=231     ctermbg=74   gui=NONE           cterm=NONE
hi CursorColumn     guisp=NONE      guifg=NONE      guibg=#F7F7F7   ctermfg=NONE    ctermbg=231  gui=NONE           cterm=NONE
hi CursorLine       guisp=NONE      guifg=NONE      guibg=#F7F7F7   ctermfg=NONE    ctermbg=231  gui=NONE           cterm=NONE
hi Directory        guisp=NONE      guifg=#2980B9   guibg=NONE      ctermfg=31      ctermbg=NONE gui=NONE           cterm=NONE
hi DiffAdd          guisp=NONE      guifg=#FCFCFC   guibg=#27AE60   ctermfg=231     ctermbg=35   gui=NONE           cterm=NONE
hi DiffChange       guisp=NONE      guifg=#232629   guibg=#F1C40F   ctermfg=235     ctermbg=220  gui=NONE           cterm=NONE
hi DiffDelete       guisp=NONE      guifg=#FCFCFC   guibg=#DA4453   ctermfg=231     ctermbg=167  gui=NONE           cterm=NONE
hi DiffText         guisp=NONE      guifg=#FCFCFC   guibg=#3DAEE9   ctermfg=231     ctermbg=74   gui=NONE           cterm=NONE
hi EndOfBuffer      guisp=NONE      guifg=NONE      guibg=NONE      ctermfg=NONE    ctermbg=NONE gui=NONE           cterm=NONE
hi ErrorMsg         guisp=NONE      guifg=#DA4453   guibg=NONE      ctermfg=167     ctermbg=NONE gui=bold,italic    cterm=bold,italic
hi VertSplit        guisp=NONE      guifg=#C7CBCF   guibg=NONE      ctermfg=251     ctermbg=NONE gui=NONE           cterm=NONE
hi Folded           guisp=NONE      guifg=#2980B9   guibg=#E3E5E7   ctermfg=31      ctermbg=254  gui=NONE           cterm=NONE
hi FoldColumn       guisp=NONE      guifg=#707D8A   guibg=#FCFCFC   ctermfg=66      ctermbg=231  gui=NONE           cterm=NONE
hi SignColumn       guisp=NONE      guifg=#C7CBCF   guibg=#FCFCFC   ctermfg=251     ctermbg=231  gui=NONE           cterm=NONE
hi IncSearch        guisp=NONE      guifg=#232629   guibg=#F1C40F   ctermfg=235     ctermbg=220  gui=NONE           cterm=NONE
hi CursorLineNR     guisp=NONE      guifg=#3DAEE9   guibg=NONE      ctermfg=74      ctermbg=NONE gui=NONE           cterm=NONE
hi LineNr           guisp=NONE      guifg=#C7CBCF   guibg=NONE      ctermfg=251     ctermbg=NONE gui=NONE           cterm=NONE
hi MatchParen       guisp=NONE      guifg=#F67400   guibg=NONE      ctermfg=208     ctermbg=NONE gui=bold           cterm=bold
hi ModeMsg          guisp=NONE      guifg=#232629   guibg=NONE      ctermfg=235     ctermbg=NONE gui=bold           cterm=bold
hi MoreMsg          guisp=NONE      guifg=#2980B9   guibg=NONE      ctermfg=31      ctermbg=NONE gui=NONE           cterm=NONE
hi NonText          guisp=NONE      guifg=#C7CBCF   guibg=NONE      ctermfg=251     ctermbg=NONE gui=NONE           cterm=NONE
hi Pmenu            guisp=NONE      guifg=#232629   guibg=#E3E5E7   ctermfg=235     ctermbg=254  gui=NONE           cterm=NONE
hi PmenuSel         guisp=NONE      guifg=#FCFCFC   guibg=#3DAEE9   ctermfg=231     ctermbg=74   gui=bold           cterm=bold
hi PmenuSbar        guisp=NONE      guifg=NONE      guibg=#E3E5E7   ctermfg=NONE    ctermbg=254  gui=NONE           cterm=NONE
hi PmenuThumb       guisp=NONE      guifg=NONE      guibg=#707D8A   ctermfg=NONE    ctermbg=66   gui=NONE           cterm=NONE
hi Question         guisp=NONE      guifg=#2980B9   guibg=NONE      ctermfg=31      ctermbg=NONE gui=NONE           cterm=NONE
hi QuickFixLine     guisp=NONE      guifg=NONE      guibg=#E3E5E7   ctermfg=NONE    ctermbg=254  gui=bold           cterm=bold
hi Search           guisp=NONE      guifg=#232629   guibg=#A3D4FA   ctermfg=235     ctermbg=153  gui=bold           cterm=bold
hi SpecialKey       guisp=NONE      guifg=#707D8A   guibg=NONE      ctermfg=66      ctermbg=NONE gui=NONE           cterm=NONE
hi SpellBad         guisp=#DA4453   guifg=NONE      guibg=NONE      ctermfg=167     ctermbg=NONE gui=underline      cterm=underline
hi SpellCap         guisp=#F1C40F   guifg=NONE      guibg=NONE      ctermfg=220     ctermbg=NONE gui=underline      cterm=underline
hi SpellLocal       guisp=#2980B9   guifg=NONE      guibg=NONE      ctermfg=31      ctermbg=NONE gui=underline      cterm=underline
hi SpellRare        guisp=#27AE60   guifg=NONE      guibg=NONE      ctermfg=35      ctermbg=NONE gui=underline      cterm=underline
hi StatusLine       guisp=NONE      guifg=#232629   guibg=#E3E5E7   ctermfg=235     ctermbg=254  gui=NONE           cterm=NONE
hi StatusLineNC     guisp=NONE      guifg=#707D8A   guibg=#E3E5E7   ctermfg=66      ctermbg=254  gui=NONE           cterm=NONE
hi TabLine          guisp=NONE      guifg=#707D8A   guibg=#E3E5E7   ctermfg=66      ctermbg=254  gui=NONE           cterm=NONE
hi TabLineFill      guisp=NONE      guifg=NONE      guibg=#E3E5E7   ctermfg=NONE    ctermbg=254  gui=NONE           cterm=NONE
hi TabLineSel       guisp=NONE      guifg=#27AE60   guibg=#FCFCFC   ctermfg=35      ctermbg=231  gui=NONE           cterm=NONE
hi Title            guisp=NONE      guifg=#2980B9   guibg=NONE      ctermfg=31      ctermbg=NONE gui=bold           cterm=bold
hi VisualNOS        guisp=NONE      guifg=NONE      guibg=#A3D4FA   ctermfg=NONE    ctermbg=153  gui=bold           cterm=bold
hi WarningMsg       guisp=NONE      guifg=#F67400   guibg=NONE      ctermfg=208     ctermbg=NONE gui=NONE           cterm=NONE
hi WildMenu         guisp=NONE      guifg=NONE      guibg=#707D8A   ctermfg=NONE    ctermbg=66   gui=NONE           cterm=NONE
hi Comment          guisp=NONE      guifg=#707D8A   guibg=NONE      ctermfg=66      ctermbg=NONE gui=NONE           cterm=NONE
hi Constant         guisp=NONE      guifg=#F67400   guibg=NONE      ctermfg=208     ctermbg=NONE gui=NONE           cterm=NONE
hi Identifier       guisp=NONE      guifg=#9B59B6   guibg=NONE      ctermfg=133     ctermbg=NONE gui=NONE           cterm=NONE
hi Statement        guisp=NONE      guifg=#9B59B6   guibg=NONE      ctermfg=133     ctermbg=NONE gui=NONE           cterm=NONE
hi PreProc          guisp=NONE      guifg=#2980B9   guibg=NONE      ctermfg=31      ctermbg=NONE gui=NONE           cterm=NONE
hi Type             guisp=NONE      guifg=#2980B9   guibg=NONE      ctermfg=31      ctermbg=NONE gui=NONE           cterm=NONE
hi Special          guisp=NONE      guifg=#1ABC9C   guibg=NONE      ctermfg=37      ctermbg=NONE gui=NONE           cterm=NONE
hi Underlined       guisp=NONE      guifg=#232629   guibg=#FCFCFC   ctermfg=235     ctermbg=231  gui=underline      cterm=underline
hi Error            guisp=NONE      guifg=#DA4453   guibg=NONE      ctermfg=167     ctermbg=NONE gui=NONE           cterm=NONE
hi Todo             guisp=NONE      guifg=#232629   guibg=#F1C40F   ctermfg=235     ctermbg=220  gui=bold           cterm=bold

hi String           guisp=NONE      guifg=#27AE60   guibg=NONE      ctermfg=35      ctermbg=NONE gui=NONE           cterm=NONE
hi Character        guisp=NONE      guifg=#1ABC9C   guibg=NONE      ctermfg=37      ctermbg=NONE gui=NONE           cterm=NONE
hi Number           guisp=NONE      guifg=#F67400   guibg=NONE      ctermfg=208     ctermbg=NONE gui=NONE           cterm=NONE
hi Boolean          guisp=NONE      guifg=#F67400   guibg=NONE      ctermfg=208     ctermbg=NONE gui=NONE           cterm=NONE
hi Float            guisp=NONE      guifg=#F67400   guibg=NONE      ctermfg=208     ctermbg=NONE gui=NONE           cterm=NONE
hi Function         guisp=NONE      guifg=#2980B9   guibg=NONE      ctermfg=31      ctermbg=NONE gui=NONE           cterm=NONE
hi Conditional      guisp=NONE      guifg=#DA4453   guibg=NONE      ctermfg=167     ctermbg=NONE gui=NONE           cterm=NONE
hi Repeat           guisp=NONE      guifg=#DA4453   guibg=NONE      ctermfg=167     ctermbg=NONE gui=NONE           cterm=NONE
hi Label            guisp=NONE      guifg=#F67400   guibg=NONE      ctermfg=208     ctermbg=NONE gui=NONE           cterm=NONE
hi Operator         guisp=NONE      guifg=#1ABC9C   guibg=NONE      ctermfg=37      ctermbg=NONE gui=NONE           cterm=NONE
hi Keyword          guisp=NONE      guifg=#9B59B6   guibg=NONE      ctermfg=133     ctermbg=NONE gui=NONE           cterm=NONE
hi Include          guisp=NONE      guifg=#9B59B6   guibg=NONE      ctermfg=133     ctermbg=NONE gui=NONE           cterm=NONE
hi StorageClass     guisp=NONE      guifg=#F1C40F   guibg=NONE      ctermfg=220     ctermbg=NONE gui=NONE           cterm=NONE
hi Structure        guisp=NONE      guifg=#F1C40F   guibg=NONE      ctermfg=220     ctermbg=NONE gui=NONE           cterm=NONE
hi Typedef          guisp=NONE      guifg=#F1C40F   guibg=NONE      ctermfg=220     ctermbg=NONE gui=NONE           cterm=NONE
hi debugPC          guisp=NONE      guifg=NONE      guibg=#E3E5E7   ctermfg=220     ctermbg=NONE gui=NONE           cterm=NONE
hi debugBreakpoint  guisp=NONE      guifg=#707D8A   guibg=#FCFCFC   ctermfg=220     ctermbg=NONE gui=NONE           cterm=NONE

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
