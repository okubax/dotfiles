" Name: harmattan_dark.vim
" Harmattan: an original warm, dust-toned colorscheme. See
" ~/dotfiles/swaywm/harmattan/README.md and dark/palette.md for the
" full palette and where each value comes from.

set background=dark
hi clear

if exists('syntax on')
    syntax reset
endif

let g:colors_name='harmattan_dark'
set t_Co=256

" bg          = "#14120D"  (near-black, warm umber undertone)
" bg_alt      = "#1C170F"  (one step lighter)
" bg_panel    = "#221C14"  (dark panel)
" bg_panel_alt= "#2B2419"  (deeper panel)
" fg          = "#F6EFDF"  (warm parchment, bright)
" fg_muted    = "#B4A687"  (dimmed sand)
" border      = "#473B29"  (umber-tan, dark)
" accent      = "#4C5FA6"  (indigo, adire-dye, unchanged from light)
" link        = "#8296D6"  (lightest indigo, dark-bg contrast)
" red/green/yellow/purple/cyan unchanged from light — see palette.md

hi Normal           guisp=NONE      guifg=#F6EFDF   guibg=#14120D   ctermfg=231     ctermbg=233  gui=NONE           cterm=NONE
hi Visual           guisp=NONE      guifg=NONE      guibg=#29335A   ctermfg=NONE    ctermbg=24   gui=bold           cterm=bold

hi Conceal          guisp=NONE      guifg=#B4A687   guibg=NONE      ctermfg=248     ctermbg=NONE gui=NONE           cterm=NONE
hi ColorColumn      guisp=NONE      guifg=NONE      guibg=#2B2419   ctermfg=NONE    ctermbg=236  gui=NONE           cterm=NONE
hi Cursor           guisp=NONE      guifg=#14120D   guibg=#4C5FA6   ctermfg=233     ctermbg=61   gui=NONE           cterm=NONE
hi lCursor          guisp=NONE      guifg=#14120D   guibg=#4C5FA6   ctermfg=233     ctermbg=61   gui=NONE           cterm=NONE
hi CursorIM         guisp=NONE      guifg=#14120D   guibg=#4C5FA6   ctermfg=233     ctermbg=61   gui=NONE           cterm=NONE
hi CursorColumn     guisp=NONE      guifg=NONE      guibg=#1C170F   ctermfg=NONE    ctermbg=234  gui=NONE           cterm=NONE
hi CursorLine       guisp=NONE      guifg=NONE      guibg=#1C170F   ctermfg=NONE    ctermbg=234  gui=NONE           cterm=NONE
hi Directory        guisp=NONE      guifg=#8296D6   guibg=NONE      ctermfg=104      ctermbg=NONE gui=NONE           cterm=NONE
hi DiffAdd          guisp=NONE      guifg=#14120D   guibg=#6E8C4E   ctermfg=233     ctermbg=65   gui=NONE           cterm=NONE
hi DiffChange       guisp=NONE      guifg=#14120D   guibg=#E8B84B   ctermfg=233     ctermbg=179  gui=NONE           cterm=NONE
hi DiffDelete       guisp=NONE      guifg=#F6EFDF   guibg=#C1502E   ctermfg=231     ctermbg=130  gui=NONE           cterm=NONE
hi DiffText         guisp=NONE      guifg=#14120D   guibg=#4C5FA6   ctermfg=233     ctermbg=61   gui=NONE           cterm=NONE
hi EndOfBuffer      guisp=NONE      guifg=NONE      guibg=NONE      ctermfg=NONE    ctermbg=NONE gui=NONE           cterm=NONE
hi ErrorMsg         guisp=NONE      guifg=#C1502E   guibg=NONE      ctermfg=130     ctermbg=NONE gui=bold,italic    cterm=bold,italic
hi VertSplit        guisp=NONE      guifg=#473B29   guibg=NONE      ctermfg=238     ctermbg=NONE gui=NONE           cterm=NONE
hi Folded           guisp=NONE      guifg=#8296D6   guibg=#2B2419   ctermfg=104      ctermbg=236  gui=NONE           cterm=NONE
hi FoldColumn       guisp=NONE      guifg=#B4A687   guibg=#14120D   ctermfg=248     ctermbg=233  gui=NONE           cterm=NONE
hi SignColumn       guisp=NONE      guifg=#473B29   guibg=#14120D   ctermfg=238     ctermbg=233  gui=NONE           cterm=NONE
hi IncSearch        guisp=NONE      guifg=#14120D   guibg=#E8B84B   ctermfg=233     ctermbg=179  gui=NONE           cterm=NONE
hi CursorLineNR     guisp=NONE      guifg=#4C5FA6   guibg=NONE      ctermfg=61      ctermbg=NONE gui=NONE           cterm=NONE
hi LineNr           guisp=NONE      guifg=#473B29   guibg=NONE      ctermfg=238     ctermbg=NONE gui=NONE           cterm=NONE
hi MatchParen       guisp=NONE      guifg=#D98A2B   guibg=NONE      ctermfg=172     ctermbg=NONE gui=bold           cterm=bold
hi ModeMsg          guisp=NONE      guifg=#F6EFDF   guibg=NONE      ctermfg=231     ctermbg=NONE gui=bold           cterm=bold
hi MoreMsg          guisp=NONE      guifg=#8296D6   guibg=NONE      ctermfg=104      ctermbg=NONE gui=NONE           cterm=NONE
hi NonText          guisp=NONE      guifg=#473B29   guibg=NONE      ctermfg=238     ctermbg=NONE gui=NONE           cterm=NONE
hi Pmenu            guisp=NONE      guifg=#F6EFDF   guibg=#2B2419   ctermfg=231     ctermbg=236  gui=NONE           cterm=NONE
hi PmenuSel         guisp=NONE      guifg=#14120D   guibg=#4C5FA6   ctermfg=233     ctermbg=61   gui=bold           cterm=bold
hi PmenuSbar        guisp=NONE      guifg=NONE      guibg=#2B2419   ctermfg=NONE    ctermbg=236  gui=NONE           cterm=NONE
hi PmenuThumb       guisp=NONE      guifg=NONE      guibg=#B4A687   ctermfg=NONE    ctermbg=248  gui=NONE           cterm=NONE
hi Question         guisp=NONE      guifg=#8296D6   guibg=NONE      ctermfg=104      ctermbg=NONE gui=NONE           cterm=NONE
hi QuickFixLine     guisp=NONE      guifg=NONE      guibg=#2B2419   ctermfg=NONE    ctermbg=236  gui=bold           cterm=bold
hi Search           guisp=NONE      guifg=#14120D   guibg=#29335A   ctermfg=233     ctermbg=24   gui=bold           cterm=bold
hi SpecialKey       guisp=NONE      guifg=#B4A687   guibg=NONE      ctermfg=248     ctermbg=NONE gui=NONE           cterm=NONE
hi SpellBad         guisp=#C1502E   guifg=NONE      guibg=NONE      ctermfg=130     ctermbg=NONE gui=underline      cterm=underline
hi SpellCap         guisp=#E8B84B   guifg=NONE      guibg=NONE      ctermfg=179     ctermbg=NONE gui=underline      cterm=underline
hi SpellLocal       guisp=#8296D6   guifg=NONE      guibg=NONE      ctermfg=104      ctermbg=NONE gui=underline      cterm=underline
hi SpellRare        guisp=#6E8C4E   guifg=NONE      guibg=NONE      ctermfg=65      ctermbg=NONE gui=underline      cterm=underline
hi StatusLine       guisp=NONE      guifg=#F6EFDF   guibg=#2B2419   ctermfg=231     ctermbg=236  gui=NONE           cterm=NONE
hi StatusLineNC     guisp=NONE      guifg=#B4A687   guibg=#2B2419   ctermfg=248     ctermbg=236  gui=NONE           cterm=NONE
hi TabLine          guisp=NONE      guifg=#B4A687   guibg=#2B2419   ctermfg=248     ctermbg=236  gui=NONE           cterm=NONE
hi TabLineFill      guisp=NONE      guifg=NONE      guibg=#2B2419   ctermfg=NONE    ctermbg=236  gui=NONE           cterm=NONE
hi TabLineSel       guisp=NONE      guifg=#6E8C4E   guibg=#14120D   ctermfg=65      ctermbg=233  gui=NONE           cterm=NONE
hi Title            guisp=NONE      guifg=#8296D6   guibg=NONE      ctermfg=104      ctermbg=NONE gui=bold           cterm=bold
hi VisualNOS        guisp=NONE      guifg=NONE      guibg=#29335A   ctermfg=NONE    ctermbg=24   gui=bold           cterm=bold
hi WarningMsg       guisp=NONE      guifg=#D98A2B   guibg=NONE      ctermfg=172     ctermbg=NONE gui=NONE           cterm=NONE
hi WildMenu         guisp=NONE      guifg=NONE      guibg=#B4A687   ctermfg=NONE    ctermbg=248  gui=NONE           cterm=NONE
hi Comment          guisp=NONE      guifg=#B4A687   guibg=NONE      ctermfg=248     ctermbg=NONE gui=NONE           cterm=NONE
hi Constant         guisp=NONE      guifg=#D98A2B   guibg=NONE      ctermfg=172     ctermbg=NONE gui=NONE           cterm=NONE
hi Identifier       guisp=NONE      guifg=#8B5A8C   guibg=NONE      ctermfg=96     ctermbg=NONE gui=NONE           cterm=NONE
hi Statement        guisp=NONE      guifg=#8B5A8C   guibg=NONE      ctermfg=96     ctermbg=NONE gui=NONE           cterm=NONE
hi PreProc          guisp=NONE      guifg=#8296D6   guibg=NONE      ctermfg=104      ctermbg=NONE gui=NONE           cterm=NONE
hi Type             guisp=NONE      guifg=#8296D6   guibg=NONE      ctermfg=104      ctermbg=NONE gui=NONE           cterm=NONE
hi Special          guisp=NONE      guifg=#3E8E8A   guibg=NONE      ctermfg=66      ctermbg=NONE gui=NONE           cterm=NONE
hi Underlined       guisp=NONE      guifg=#F6EFDF   guibg=#14120D   ctermfg=231     ctermbg=233  gui=underline      cterm=underline
hi Error            guisp=NONE      guifg=#C1502E   guibg=NONE      ctermfg=130     ctermbg=NONE gui=NONE           cterm=NONE
hi Todo             guisp=NONE      guifg=#14120D   guibg=#E8B84B   ctermfg=233     ctermbg=179  gui=bold           cterm=bold

hi String           guisp=NONE      guifg=#6E8C4E   guibg=NONE      ctermfg=65      ctermbg=NONE gui=NONE           cterm=NONE
hi Character        guisp=NONE      guifg=#3E8E8A   guibg=NONE      ctermfg=66      ctermbg=NONE gui=NONE           cterm=NONE
hi Number           guisp=NONE      guifg=#D98A2B   guibg=NONE      ctermfg=172     ctermbg=NONE gui=NONE           cterm=NONE
hi Boolean          guisp=NONE      guifg=#D98A2B   guibg=NONE      ctermfg=172     ctermbg=NONE gui=NONE           cterm=NONE
hi Float            guisp=NONE      guifg=#D98A2B   guibg=NONE      ctermfg=172     ctermbg=NONE gui=NONE           cterm=NONE
hi Function         guisp=NONE      guifg=#8296D6   guibg=NONE      ctermfg=104      ctermbg=NONE gui=NONE           cterm=NONE
hi Conditional      guisp=NONE      guifg=#C1502E   guibg=NONE      ctermfg=130     ctermbg=NONE gui=NONE           cterm=NONE
hi Repeat           guisp=NONE      guifg=#C1502E   guibg=NONE      ctermfg=130     ctermbg=NONE gui=NONE           cterm=NONE
hi Label            guisp=NONE      guifg=#D98A2B   guibg=NONE      ctermfg=172     ctermbg=NONE gui=NONE           cterm=NONE
hi Operator         guisp=NONE      guifg=#3E8E8A   guibg=NONE      ctermfg=66      ctermbg=NONE gui=NONE           cterm=NONE
hi Keyword          guisp=NONE      guifg=#8B5A8C   guibg=NONE      ctermfg=96     ctermbg=NONE gui=NONE           cterm=NONE
hi Include          guisp=NONE      guifg=#8B5A8C   guibg=NONE      ctermfg=96     ctermbg=NONE gui=NONE           cterm=NONE
hi StorageClass     guisp=NONE      guifg=#E8B84B   guibg=NONE      ctermfg=179     ctermbg=NONE gui=NONE           cterm=NONE
hi Structure        guisp=NONE      guifg=#E8B84B   guibg=NONE      ctermfg=179     ctermbg=NONE gui=NONE           cterm=NONE
hi Typedef          guisp=NONE      guifg=#E8B84B   guibg=NONE      ctermfg=179     ctermbg=NONE gui=NONE           cterm=NONE
hi debugPC          guisp=NONE      guifg=NONE      guibg=#2B2419   ctermfg=179     ctermbg=NONE gui=NONE           cterm=NONE
hi debugBreakpoint  guisp=NONE      guifg=#B4A687   guibg=#14120D   ctermfg=179     ctermbg=NONE gui=NONE           cterm=NONE

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
