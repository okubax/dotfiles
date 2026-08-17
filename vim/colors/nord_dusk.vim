" Name: nord_dusk.vim
" Nord Dusk: Nord's Polar Night range shifted one step lighter than Dark,
" for a dimmer, lower-contrast dark theme. See
" ~/dotfiles/swaywm/nord/README.md and dusk/palette.md for the full
" palette and where each value comes from.

set background=dark
hi clear

if exists('syntax on')
    syntax reset
endif

let g:colors_name='nord_dusk'
set t_Co=256

" bg          = "#3B4252"  (Nord nord1, Polar Night)
" bg_alt      = "#434C5E"  (Nord nord2, Polar Night)
" bg_panel    = "#4C566A"  (Nord nord3, Polar Night)
" bg_panel_alt= "#929AA9"  (interpolated, nord3->nord4)
" fg          = "#ECEFF4"  (Nord nord6, Snow Storm)
" fg_muted    = "#D8DEE9"  (Nord nord4, Snow Storm)
" border      = "#929AA9"  (interpolated, nord3->nord4, reused)
" accent      = "#88C0D0"  (Nord nord8, Frost, unchanged all variants)
" link        = "#81A1C1"  (Nord nord9, Frost, dusk/dark weight)
" red/green/yellow/purple/cyan/orange unchanged across variants — see palette.md

hi Normal           guisp=NONE      guifg=#ECEFF4   guibg=#3B4252   ctermfg=255     ctermbg=237  gui=NONE           cterm=NONE
hi Visual           guisp=NONE      guifg=NONE      guibg=#4A6873   ctermfg=NONE    ctermbg=24   gui=bold           cterm=bold

hi Conceal          guisp=NONE      guifg=#D8DEE9   guibg=NONE      ctermfg=253     ctermbg=NONE gui=NONE           cterm=NONE
hi ColorColumn      guisp=NONE      guifg=NONE      guibg=#929AA9   ctermfg=NONE    ctermbg=239  gui=NONE           cterm=NONE
hi Cursor           guisp=NONE      guifg=#3B4252   guibg=#88C0D0   ctermfg=237     ctermbg=110   gui=NONE           cterm=NONE
hi lCursor          guisp=NONE      guifg=#3B4252   guibg=#88C0D0   ctermfg=237     ctermbg=110   gui=NONE           cterm=NONE
hi CursorIM         guisp=NONE      guifg=#3B4252   guibg=#88C0D0   ctermfg=237     ctermbg=110   gui=NONE           cterm=NONE
hi CursorColumn     guisp=NONE      guifg=NONE      guibg=#434C5E   ctermfg=NONE    ctermbg=238  gui=NONE           cterm=NONE
hi CursorLine       guisp=NONE      guifg=NONE      guibg=#434C5E   ctermfg=NONE    ctermbg=238  gui=NONE           cterm=NONE
hi Directory        guisp=NONE      guifg=#81A1C1   guibg=NONE      ctermfg=109      ctermbg=NONE gui=NONE           cterm=NONE
hi DiffAdd          guisp=NONE      guifg=#3B4252   guibg=#A3BE8C   ctermfg=237     ctermbg=150   gui=NONE           cterm=NONE
hi DiffChange       guisp=NONE      guifg=#3B4252   guibg=#D08770   ctermfg=237     ctermbg=173  gui=NONE           cterm=NONE
hi DiffDelete       guisp=NONE      guifg=#ECEFF4   guibg=#BF616A   ctermfg=255     ctermbg=131  gui=NONE           cterm=NONE
hi DiffText         guisp=NONE      guifg=#3B4252   guibg=#88C0D0   ctermfg=237     ctermbg=110   gui=NONE           cterm=NONE
hi EndOfBuffer      guisp=NONE      guifg=NONE      guibg=NONE      ctermfg=NONE    ctermbg=NONE gui=NONE           cterm=NONE
hi ErrorMsg         guisp=NONE      guifg=#BF616A   guibg=NONE      ctermfg=131     ctermbg=NONE gui=bold,italic    cterm=bold,italic
hi VertSplit        guisp=NONE      guifg=#929AA9   guibg=NONE      ctermfg=248     ctermbg=NONE gui=NONE           cterm=NONE
hi Folded           guisp=NONE      guifg=#81A1C1   guibg=#929AA9   ctermfg=109      ctermbg=239  gui=NONE           cterm=NONE
hi FoldColumn       guisp=NONE      guifg=#D8DEE9   guibg=#3B4252   ctermfg=253     ctermbg=237  gui=NONE           cterm=NONE
hi SignColumn       guisp=NONE      guifg=#929AA9   guibg=#3B4252   ctermfg=248     ctermbg=237  gui=NONE           cterm=NONE
hi IncSearch        guisp=NONE      guifg=#3B4252   guibg=#D08770   ctermfg=237     ctermbg=173  gui=NONE           cterm=NONE
hi CursorLineNR     guisp=NONE      guifg=#88C0D0   guibg=NONE      ctermfg=110      ctermbg=NONE gui=NONE           cterm=NONE
hi LineNr           guisp=NONE      guifg=#929AA9   guibg=NONE      ctermfg=248     ctermbg=NONE gui=NONE           cterm=NONE
hi MatchParen       guisp=NONE      guifg=#EBCB8B   guibg=NONE      ctermfg=222     ctermbg=NONE gui=bold           cterm=bold
hi ModeMsg          guisp=NONE      guifg=#ECEFF4   guibg=NONE      ctermfg=255     ctermbg=NONE gui=bold           cterm=bold
hi MoreMsg          guisp=NONE      guifg=#81A1C1   guibg=NONE      ctermfg=109      ctermbg=NONE gui=NONE           cterm=NONE
hi NonText          guisp=NONE      guifg=#929AA9   guibg=NONE      ctermfg=248     ctermbg=NONE gui=NONE           cterm=NONE
hi Pmenu            guisp=NONE      guifg=#ECEFF4   guibg=#929AA9   ctermfg=255     ctermbg=239  gui=NONE           cterm=NONE
hi PmenuSel         guisp=NONE      guifg=#3B4252   guibg=#88C0D0   ctermfg=237     ctermbg=110   gui=bold           cterm=bold
hi PmenuSbar        guisp=NONE      guifg=NONE      guibg=#929AA9   ctermfg=NONE    ctermbg=239  gui=NONE           cterm=NONE
hi PmenuThumb       guisp=NONE      guifg=NONE      guibg=#D8DEE9   ctermfg=NONE    ctermbg=253  gui=NONE           cterm=NONE
hi Question         guisp=NONE      guifg=#81A1C1   guibg=NONE      ctermfg=109      ctermbg=NONE gui=NONE           cterm=NONE
hi QuickFixLine     guisp=NONE      guifg=NONE      guibg=#929AA9   ctermfg=NONE    ctermbg=239  gui=bold           cterm=bold
hi Search           guisp=NONE      guifg=#3B4252   guibg=#4A6873   ctermfg=237     ctermbg=24   gui=bold           cterm=bold
hi SpecialKey       guisp=NONE      guifg=#D8DEE9   guibg=NONE      ctermfg=253     ctermbg=NONE gui=NONE           cterm=NONE
hi SpellBad         guisp=#BF616A   guifg=NONE      guibg=NONE      ctermfg=131     ctermbg=NONE gui=underline      cterm=underline
hi SpellCap         guisp=#D08770   guifg=NONE      guibg=NONE      ctermfg=173     ctermbg=NONE gui=underline      cterm=underline
hi SpellLocal       guisp=#81A1C1   guifg=NONE      guibg=NONE      ctermfg=109      ctermbg=NONE gui=underline      cterm=underline
hi SpellRare        guisp=#A3BE8C   guifg=NONE      guibg=NONE      ctermfg=150      ctermbg=NONE gui=underline      cterm=underline
hi StatusLine       guisp=NONE      guifg=#ECEFF4   guibg=#929AA9   ctermfg=255     ctermbg=239  gui=NONE           cterm=NONE
hi StatusLineNC     guisp=NONE      guifg=#D8DEE9   guibg=#929AA9   ctermfg=253     ctermbg=239  gui=NONE           cterm=NONE
hi TabLine          guisp=NONE      guifg=#D8DEE9   guibg=#929AA9   ctermfg=253     ctermbg=239  gui=NONE           cterm=NONE
hi TabLineFill      guisp=NONE      guifg=NONE      guibg=#929AA9   ctermfg=NONE    ctermbg=239  gui=NONE           cterm=NONE
hi TabLineSel       guisp=NONE      guifg=#A3BE8C   guibg=#3B4252   ctermfg=150      ctermbg=237  gui=NONE           cterm=NONE
hi Title            guisp=NONE      guifg=#81A1C1   guibg=NONE      ctermfg=109      ctermbg=NONE gui=bold           cterm=bold
hi VisualNOS        guisp=NONE      guifg=NONE      guibg=#4A6873   ctermfg=NONE    ctermbg=24   gui=bold           cterm=bold
hi WarningMsg       guisp=NONE      guifg=#EBCB8B   guibg=NONE      ctermfg=222     ctermbg=NONE gui=NONE           cterm=NONE
hi WildMenu         guisp=NONE      guifg=NONE      guibg=#D8DEE9   ctermfg=NONE    ctermbg=253  gui=NONE           cterm=NONE
hi Comment          guisp=NONE      guifg=#D8DEE9   guibg=NONE      ctermfg=253     ctermbg=NONE gui=NONE           cterm=NONE
hi Constant         guisp=NONE      guifg=#EBCB8B   guibg=NONE      ctermfg=222     ctermbg=NONE gui=NONE           cterm=NONE
hi Identifier       guisp=NONE      guifg=#B48EAD   guibg=NONE      ctermfg=139     ctermbg=NONE gui=NONE           cterm=NONE
hi Statement        guisp=NONE      guifg=#B48EAD   guibg=NONE      ctermfg=139     ctermbg=NONE gui=NONE           cterm=NONE
hi PreProc          guisp=NONE      guifg=#81A1C1   guibg=NONE      ctermfg=109      ctermbg=NONE gui=NONE           cterm=NONE
hi Type             guisp=NONE      guifg=#81A1C1   guibg=NONE      ctermfg=109      ctermbg=NONE gui=NONE           cterm=NONE
hi Special          guisp=NONE      guifg=#8FBCBB   guibg=NONE      ctermfg=108      ctermbg=NONE gui=NONE           cterm=NONE
hi Underlined       guisp=NONE      guifg=#ECEFF4   guibg=#3B4252   ctermfg=255     ctermbg=237  gui=underline      cterm=underline
hi Error            guisp=NONE      guifg=#BF616A   guibg=NONE      ctermfg=131     ctermbg=NONE gui=NONE           cterm=NONE
hi Todo             guisp=NONE      guifg=#3B4252   guibg=#D08770   ctermfg=237     ctermbg=173  gui=bold           cterm=bold

hi String           guisp=NONE      guifg=#A3BE8C   guibg=NONE      ctermfg=150      ctermbg=NONE gui=NONE           cterm=NONE
hi Character        guisp=NONE      guifg=#8FBCBB   guibg=NONE      ctermfg=108      ctermbg=NONE gui=NONE           cterm=NONE
hi Number           guisp=NONE      guifg=#EBCB8B   guibg=NONE      ctermfg=222     ctermbg=NONE gui=NONE           cterm=NONE
hi Boolean          guisp=NONE      guifg=#EBCB8B   guibg=NONE      ctermfg=222     ctermbg=NONE gui=NONE           cterm=NONE
hi Float            guisp=NONE      guifg=#EBCB8B   guibg=NONE      ctermfg=222     ctermbg=NONE gui=NONE           cterm=NONE
hi Function         guisp=NONE      guifg=#81A1C1   guibg=NONE      ctermfg=109      ctermbg=NONE gui=NONE           cterm=NONE
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
hi debugBreakpoint  guisp=NONE      guifg=#D8DEE9   guibg=#3B4252   ctermfg=173     ctermbg=NONE gui=NONE           cterm=NONE

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
