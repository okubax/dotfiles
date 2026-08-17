" Name: harmattan_light.vim
" Harmattan: an original warm, dust-toned colorscheme. See
" ~/dotfiles/swaywm/harmattan/README.md and light/palette.md for the
" full palette and where each value comes from.

set background=light
hi clear

if exists('syntax on')
    syntax reset
endif

let g:colors_name='harmattan_light'
set t_Co=256

" bg          = "#FBF7F0"  (warm sand-paper ivory)
" bg_alt      = "#F5EFE1"  (one step deeper)
" bg_panel    = "#ECE2CC"  (pale sand)
" bg_panel_alt= "#DED0B0"  (deeper sand)
" fg          = "#2B2116"  (dark roasted-earth brown)
" fg_muted    = "#7C6E56"  (warm taupe)
" border      = "#C9BA96"  (sand-tan)
" accent      = "#4C5FA6"  (indigo, adire-dye)
" link        = "#34468C"  (darker indigo, light-bg contrast)
" red         = "#C1502E"  (terracotta)
" green       = "#6E8C4E"  (acacia/olive)
" yellow      = "#D98A2B"  (ochre)
" purple      = "#8B5A8C"  (bougainvillea)
" cyan        = "#3E8E8A"  (harmattan sky)
" red_bright  = "#E06A45" | green_bright = "#8FB06A"
" yellow_bright = "#E8B84B" | purple_bright = "#A876A8" | cyan_bright = "#5FADA8"

hi Normal           guisp=NONE      guifg=#2B2116   guibg=#FBF7F0   ctermfg=16     ctermbg=231  gui=NONE           cterm=NONE
hi Visual           guisp=NONE      guifg=NONE      guibg=#C9D1EC   ctermfg=NONE    ctermbg=189  gui=bold           cterm=bold

hi Conceal          guisp=NONE      guifg=#7C6E56   guibg=NONE      ctermfg=95      ctermbg=NONE gui=NONE           cterm=NONE
hi ColorColumn      guisp=NONE      guifg=NONE      guibg=#DED0B0   ctermfg=NONE    ctermbg=187  gui=NONE           cterm=NONE
hi Cursor           guisp=NONE      guifg=#FBF7F0   guibg=#4C5FA6   ctermfg=231     ctermbg=61   gui=NONE           cterm=NONE
hi lCursor          guisp=NONE      guifg=#FBF7F0   guibg=#4C5FA6   ctermfg=231     ctermbg=61   gui=NONE           cterm=NONE
hi CursorIM         guisp=NONE      guifg=#FBF7F0   guibg=#4C5FA6   ctermfg=231     ctermbg=61   gui=NONE           cterm=NONE
hi CursorColumn     guisp=NONE      guifg=NONE      guibg=#F5EFE1   ctermfg=NONE    ctermbg=231  gui=NONE           cterm=NONE
hi CursorLine       guisp=NONE      guifg=NONE      guibg=#F5EFE1   ctermfg=NONE    ctermbg=231  gui=NONE           cterm=NONE
hi Directory        guisp=NONE      guifg=#34468C   guibg=NONE      ctermfg=60      ctermbg=NONE gui=NONE           cterm=NONE
hi DiffAdd          guisp=NONE      guifg=#FBF7F0   guibg=#6E8C4E   ctermfg=231     ctermbg=65   gui=NONE           cterm=NONE
hi DiffChange       guisp=NONE      guifg=#2B2116   guibg=#E8B84B   ctermfg=16     ctermbg=179  gui=NONE           cterm=NONE
hi DiffDelete       guisp=NONE      guifg=#FBF7F0   guibg=#C1502E   ctermfg=231     ctermbg=130  gui=NONE           cterm=NONE
hi DiffText         guisp=NONE      guifg=#FBF7F0   guibg=#4C5FA6   ctermfg=231     ctermbg=61   gui=NONE           cterm=NONE
hi EndOfBuffer      guisp=NONE      guifg=NONE      guibg=NONE      ctermfg=NONE    ctermbg=NONE gui=NONE           cterm=NONE
hi ErrorMsg         guisp=NONE      guifg=#C1502E   guibg=NONE      ctermfg=130     ctermbg=NONE gui=bold,italic    cterm=bold,italic
hi VertSplit        guisp=NONE      guifg=#C9BA96   guibg=NONE      ctermfg=180     ctermbg=NONE gui=NONE           cterm=NONE
hi Folded           guisp=NONE      guifg=#34468C   guibg=#DED0B0   ctermfg=60      ctermbg=187  gui=NONE           cterm=NONE
hi FoldColumn       guisp=NONE      guifg=#7C6E56   guibg=#FBF7F0   ctermfg=95      ctermbg=231  gui=NONE           cterm=NONE
hi SignColumn       guisp=NONE      guifg=#C9BA96   guibg=#FBF7F0   ctermfg=180     ctermbg=231  gui=NONE           cterm=NONE
hi IncSearch        guisp=NONE      guifg=#2B2116   guibg=#E8B84B   ctermfg=16     ctermbg=179  gui=NONE           cterm=NONE
hi CursorLineNR     guisp=NONE      guifg=#4C5FA6   guibg=NONE      ctermfg=61      ctermbg=NONE gui=NONE           cterm=NONE
hi LineNr           guisp=NONE      guifg=#C9BA96   guibg=NONE      ctermfg=180     ctermbg=NONE gui=NONE           cterm=NONE
hi MatchParen       guisp=NONE      guifg=#D98A2B   guibg=NONE      ctermfg=172     ctermbg=NONE gui=bold           cterm=bold
hi ModeMsg          guisp=NONE      guifg=#2B2116   guibg=NONE      ctermfg=16     ctermbg=NONE gui=bold           cterm=bold
hi MoreMsg          guisp=NONE      guifg=#34468C   guibg=NONE      ctermfg=60      ctermbg=NONE gui=NONE           cterm=NONE
hi NonText          guisp=NONE      guifg=#C9BA96   guibg=NONE      ctermfg=180     ctermbg=NONE gui=NONE           cterm=NONE
hi Pmenu            guisp=NONE      guifg=#2B2116   guibg=#DED0B0   ctermfg=16     ctermbg=187  gui=NONE           cterm=NONE
hi PmenuSel         guisp=NONE      guifg=#FBF7F0   guibg=#4C5FA6   ctermfg=231     ctermbg=61   gui=bold           cterm=bold
hi PmenuSbar        guisp=NONE      guifg=NONE      guibg=#DED0B0   ctermfg=NONE    ctermbg=187  gui=NONE           cterm=NONE
hi PmenuThumb       guisp=NONE      guifg=NONE      guibg=#7C6E56   ctermfg=NONE    ctermbg=95   gui=NONE           cterm=NONE
hi Question         guisp=NONE      guifg=#34468C   guibg=NONE      ctermfg=60      ctermbg=NONE gui=NONE           cterm=NONE
hi QuickFixLine     guisp=NONE      guifg=NONE      guibg=#DED0B0   ctermfg=NONE    ctermbg=187  gui=bold           cterm=bold
hi Search           guisp=NONE      guifg=#2B2116   guibg=#C9D1EC   ctermfg=16     ctermbg=189  gui=bold           cterm=bold
hi SpecialKey       guisp=NONE      guifg=#7C6E56   guibg=NONE      ctermfg=95      ctermbg=NONE gui=NONE           cterm=NONE
hi SpellBad         guisp=#C1502E   guifg=NONE      guibg=NONE      ctermfg=130     ctermbg=NONE gui=underline      cterm=underline
hi SpellCap         guisp=#E8B84B   guifg=NONE      guibg=NONE      ctermfg=179     ctermbg=NONE gui=underline      cterm=underline
hi SpellLocal       guisp=#34468C   guifg=NONE      guibg=NONE      ctermfg=60      ctermbg=NONE gui=underline      cterm=underline
hi SpellRare        guisp=#6E8C4E   guifg=NONE      guibg=NONE      ctermfg=65      ctermbg=NONE gui=underline      cterm=underline
hi StatusLine       guisp=NONE      guifg=#2B2116   guibg=#DED0B0   ctermfg=16     ctermbg=187  gui=NONE           cterm=NONE
hi StatusLineNC     guisp=NONE      guifg=#7C6E56   guibg=#DED0B0   ctermfg=95      ctermbg=187  gui=NONE           cterm=NONE
hi TabLine          guisp=NONE      guifg=#7C6E56   guibg=#DED0B0   ctermfg=95      ctermbg=187  gui=NONE           cterm=NONE
hi TabLineFill      guisp=NONE      guifg=NONE      guibg=#DED0B0   ctermfg=NONE    ctermbg=187  gui=NONE           cterm=NONE
hi TabLineSel       guisp=NONE      guifg=#6E8C4E   guibg=#FBF7F0   ctermfg=65      ctermbg=231  gui=NONE           cterm=NONE
hi Title            guisp=NONE      guifg=#34468C   guibg=NONE      ctermfg=60      ctermbg=NONE gui=bold           cterm=bold
hi VisualNOS        guisp=NONE      guifg=NONE      guibg=#C9D1EC   ctermfg=NONE    ctermbg=189  gui=bold           cterm=bold
hi WarningMsg       guisp=NONE      guifg=#D98A2B   guibg=NONE      ctermfg=172     ctermbg=NONE gui=NONE           cterm=NONE
hi WildMenu         guisp=NONE      guifg=NONE      guibg=#7C6E56   ctermfg=NONE    ctermbg=95   gui=NONE           cterm=NONE
hi Comment          guisp=NONE      guifg=#7C6E56   guibg=NONE      ctermfg=95      ctermbg=NONE gui=NONE           cterm=NONE
hi Constant         guisp=NONE      guifg=#D98A2B   guibg=NONE      ctermfg=172     ctermbg=NONE gui=NONE           cterm=NONE
hi Identifier       guisp=NONE      guifg=#8B5A8C   guibg=NONE      ctermfg=96     ctermbg=NONE gui=NONE           cterm=NONE
hi Statement        guisp=NONE      guifg=#8B5A8C   guibg=NONE      ctermfg=96     ctermbg=NONE gui=NONE           cterm=NONE
hi PreProc          guisp=NONE      guifg=#34468C   guibg=NONE      ctermfg=60      ctermbg=NONE gui=NONE           cterm=NONE
hi Type             guisp=NONE      guifg=#34468C   guibg=NONE      ctermfg=60      ctermbg=NONE gui=NONE           cterm=NONE
hi Special          guisp=NONE      guifg=#3E8E8A   guibg=NONE      ctermfg=66      ctermbg=NONE gui=NONE           cterm=NONE
hi Underlined       guisp=NONE      guifg=#2B2116   guibg=#FBF7F0   ctermfg=16     ctermbg=231  gui=underline      cterm=underline
hi Error            guisp=NONE      guifg=#C1502E   guibg=NONE      ctermfg=130     ctermbg=NONE gui=NONE           cterm=NONE
hi Todo             guisp=NONE      guifg=#2B2116   guibg=#E8B84B   ctermfg=16     ctermbg=179  gui=bold           cterm=bold

hi String           guisp=NONE      guifg=#6E8C4E   guibg=NONE      ctermfg=65      ctermbg=NONE gui=NONE           cterm=NONE
hi Character        guisp=NONE      guifg=#3E8E8A   guibg=NONE      ctermfg=66      ctermbg=NONE gui=NONE           cterm=NONE
hi Number           guisp=NONE      guifg=#D98A2B   guibg=NONE      ctermfg=172     ctermbg=NONE gui=NONE           cterm=NONE
hi Boolean          guisp=NONE      guifg=#D98A2B   guibg=NONE      ctermfg=172     ctermbg=NONE gui=NONE           cterm=NONE
hi Float            guisp=NONE      guifg=#D98A2B   guibg=NONE      ctermfg=172     ctermbg=NONE gui=NONE           cterm=NONE
hi Function         guisp=NONE      guifg=#34468C   guibg=NONE      ctermfg=60      ctermbg=NONE gui=NONE           cterm=NONE
hi Conditional      guisp=NONE      guifg=#C1502E   guibg=NONE      ctermfg=130     ctermbg=NONE gui=NONE           cterm=NONE
hi Repeat           guisp=NONE      guifg=#C1502E   guibg=NONE      ctermfg=130     ctermbg=NONE gui=NONE           cterm=NONE
hi Label            guisp=NONE      guifg=#D98A2B   guibg=NONE      ctermfg=172     ctermbg=NONE gui=NONE           cterm=NONE
hi Operator         guisp=NONE      guifg=#3E8E8A   guibg=NONE      ctermfg=66      ctermbg=NONE gui=NONE           cterm=NONE
hi Keyword          guisp=NONE      guifg=#8B5A8C   guibg=NONE      ctermfg=96     ctermbg=NONE gui=NONE           cterm=NONE
hi Include          guisp=NONE      guifg=#8B5A8C   guibg=NONE      ctermfg=96     ctermbg=NONE gui=NONE           cterm=NONE
hi StorageClass     guisp=NONE      guifg=#E8B84B   guibg=NONE      ctermfg=179     ctermbg=NONE gui=NONE           cterm=NONE
hi Structure        guisp=NONE      guifg=#E8B84B   guibg=NONE      ctermfg=179     ctermbg=NONE gui=NONE           cterm=NONE
hi Typedef          guisp=NONE      guifg=#E8B84B   guibg=NONE      ctermfg=179     ctermbg=NONE gui=NONE           cterm=NONE
hi debugPC          guisp=NONE      guifg=NONE      guibg=#DED0B0   ctermfg=179     ctermbg=NONE gui=NONE           cterm=NONE
hi debugBreakpoint  guisp=NONE      guifg=#7C6E56   guibg=#FBF7F0   ctermfg=179     ctermbg=NONE gui=NONE           cterm=NONE

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
