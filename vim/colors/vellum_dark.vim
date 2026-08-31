" Name: vellum_dark.vim
" Vellum Dark: strict grayscale (R=G=B throughout), no hue anywhere.
" See ~/.cfg-tzevaot/swaywm/vellum/README.md and dark/palette.md
" for the full palette and the cyan->link / orange->yellow hue collapse.

set background=dark
hi clear

if exists('syntax on')
    syntax reset
endif

let g:colors_name='vellum_dark'
set t_Co=256

hi Normal             guisp=NONE      guifg=#DCDCDC  guibg=#2E2E2E  gui=NONE     cterm=NONE
hi Visual             guisp=NONE      guifg=NONE     guibg=#E6E6E6  gui=bold     cterm=bold
hi Conceal            guisp=NONE      guifg=#8C8C8C  guibg=NONE     gui=NONE     cterm=NONE
hi ColorColumn        guisp=NONE      guifg=NONE     guibg=#464646  gui=NONE     cterm=NONE
hi Cursor             guisp=NONE      guifg=#2E2E2E  guibg=#E6E6E6  gui=NONE     cterm=NONE
hi lCursor            guisp=NONE      guifg=#2E2E2E  guibg=#E6E6E6  gui=NONE     cterm=NONE
hi CursorIM           guisp=NONE      guifg=#2E2E2E  guibg=#E6E6E6  gui=NONE     cterm=NONE
hi CursorColumn       guisp=NONE      guifg=NONE     guibg=#363636  gui=NONE     cterm=NONE
hi CursorLine         guisp=NONE      guifg=NONE     guibg=#363636  gui=NONE     cterm=NONE
hi Directory          guisp=NONE      guifg=#C6C6C6  guibg=NONE     gui=NONE     cterm=NONE
hi DiffAdd            guisp=NONE      guifg=#2E2E2E  guibg=#B4B4B4  gui=NONE     cterm=NONE
hi DiffChange         guisp=NONE      guifg=#2E2E2E  guibg=#A2A2A2  gui=NONE     cterm=NONE
hi DiffDelete         guisp=NONE      guifg=#DCDCDC  guibg=#D2D2D2  gui=NONE     cterm=NONE
hi DiffText           guisp=NONE      guifg=#2E2E2E  guibg=#E6E6E6  gui=NONE     cterm=NONE
hi EndOfBuffer        guisp=NONE      guifg=NONE     guibg=NONE     gui=NONE     cterm=NONE
hi ErrorMsg           guisp=NONE      guifg=#D2D2D2  guibg=NONE     gui=bold,italic cterm=bold,italic
hi VertSplit          guisp=NONE      guifg=#5E5E5E  guibg=NONE     gui=NONE     cterm=NONE
hi Folded             guisp=NONE      guifg=#C6C6C6  guibg=#5E5E5E  gui=NONE     cterm=NONE
hi FoldColumn         guisp=NONE      guifg=#5E5E5E  guibg=#2E2E2E  gui=NONE     cterm=NONE
hi SignColumn         guisp=NONE      guifg=#5E5E5E  guibg=#2E2E2E  gui=NONE     cterm=NONE
hi IncSearch          guisp=NONE      guifg=#2E2E2E  guibg=#A2A2A2  gui=NONE     cterm=NONE
hi CursorLineNR       guisp=NONE      guifg=#E6E6E6  guibg=NONE     gui=NONE     cterm=NONE
hi LineNr             guisp=NONE      guifg=#5E5E5E  guibg=NONE     gui=NONE     cterm=NONE
hi MatchParen         guisp=NONE      guifg=#A2A2A2  guibg=NONE     gui=bold     cterm=bold
hi ModeMsg            guisp=NONE      guifg=#DCDCDC  guibg=NONE     gui=bold     cterm=bold
hi MoreMsg            guisp=NONE      guifg=#C6C6C6  guibg=NONE     gui=NONE     cterm=NONE
hi NonText            guisp=NONE      guifg=#5E5E5E  guibg=NONE     gui=NONE     cterm=NONE
hi Pmenu              guisp=NONE      guifg=#DCDCDC  guibg=#5E5E5E  gui=NONE     cterm=NONE
hi PmenuSel           guisp=NONE      guifg=#2E2E2E  guibg=#E6E6E6  gui=NONE     cterm=NONE
hi PmenuSbar          guisp=NONE      guifg=NONE     guibg=#5E5E5E  gui=NONE     cterm=NONE
hi PmenuThumb         guisp=NONE      guifg=NONE     guibg=#5E5E5E  gui=NONE     cterm=NONE
hi Question           guisp=NONE      guifg=#C6C6C6  guibg=NONE     gui=NONE     cterm=NONE
hi QuickFixLine       guisp=NONE      guifg=NONE     guibg=#5E5E5E  gui=bold     cterm=bold
hi Search             guisp=NONE      guifg=#2E2E2E  guibg=#E6E6E6  gui=bold     cterm=bold
hi SpecialKey         guisp=NONE      guifg=#5E5E5E  guibg=NONE     gui=NONE     cterm=NONE
hi StatusLine         guisp=NONE      guifg=#DCDCDC  guibg=#5E5E5E  gui=NONE     cterm=NONE
hi StatusLineNC       guisp=NONE      guifg=#5E5E5E  guibg=#5E5E5E  gui=NONE     cterm=NONE
hi TabLine            guisp=NONE      guifg=#5E5E5E  guibg=#5E5E5E  gui=NONE     cterm=NONE
hi TabLineFill        guisp=NONE      guifg=NONE     guibg=#5E5E5E  gui=NONE     cterm=NONE
hi TabLineSel         guisp=NONE      guifg=#B4B4B4  guibg=#2E2E2E  gui=bold     cterm=bold
hi Title              guisp=NONE      guifg=#C6C6C6  guibg=NONE     gui=NONE     cterm=NONE
hi VisualNOS          guisp=NONE      guifg=NONE     guibg=#E6E6E6  gui=bold     cterm=bold
hi WarningMsg         guisp=NONE      guifg=#A2A2A2  guibg=NONE     gui=NONE     cterm=NONE
hi WildMenu           guisp=NONE      guifg=NONE     guibg=#5E5E5E  gui=NONE     cterm=NONE
hi Comment            guisp=NONE      guifg=#8C8C8C  guibg=NONE     gui=NONE     cterm=NONE
hi Constant           guisp=NONE      guifg=#A2A2A2  guibg=NONE     gui=NONE     cterm=NONE
hi Identifier         guisp=NONE      guifg=#9E9E9E  guibg=NONE     gui=NONE     cterm=NONE
hi Statement          guisp=NONE      guifg=#9E9E9E  guibg=NONE     gui=NONE     cterm=NONE
hi PreProc            guisp=NONE      guifg=#C6C6C6  guibg=NONE     gui=NONE     cterm=NONE
hi Type               guisp=NONE      guifg=#C6C6C6  guibg=NONE     gui=NONE     cterm=NONE
hi Special            guisp=NONE      guifg=#C6C6C6  guibg=NONE     gui=NONE     cterm=NONE
hi Underlined         guisp=NONE      guifg=#DCDCDC  guibg=#2E2E2E  gui=underline cterm=underline
hi Error              guisp=NONE      guifg=#D2D2D2  guibg=NONE     gui=NONE     cterm=NONE
hi Todo               guisp=NONE      guifg=#2E2E2E  guibg=#A2A2A2  gui=NONE     cterm=NONE
hi String             guisp=NONE      guifg=#B4B4B4  guibg=NONE     gui=NONE     cterm=NONE
hi Character          guisp=NONE      guifg=#C6C6C6  guibg=NONE     gui=NONE     cterm=NONE
hi Number             guisp=NONE      guifg=#A2A2A2  guibg=NONE     gui=NONE     cterm=NONE
hi Boolean            guisp=NONE      guifg=#A2A2A2  guibg=NONE     gui=NONE     cterm=NONE
hi Float              guisp=NONE      guifg=#A2A2A2  guibg=NONE     gui=NONE     cterm=NONE
hi Function           guisp=NONE      guifg=#C6C6C6  guibg=NONE     gui=NONE     cterm=NONE
hi Conditional        guisp=NONE      guifg=#D2D2D2  guibg=NONE     gui=NONE     cterm=NONE
hi Repeat             guisp=NONE      guifg=#D2D2D2  guibg=NONE     gui=NONE     cterm=NONE
hi Label              guisp=NONE      guifg=#A2A2A2  guibg=NONE     gui=NONE     cterm=NONE
hi Operator           guisp=NONE      guifg=#C6C6C6  guibg=NONE     gui=NONE     cterm=NONE
hi Keyword            guisp=NONE      guifg=#9E9E9E  guibg=NONE     gui=NONE     cterm=NONE
hi Include            guisp=NONE      guifg=#9E9E9E  guibg=NONE     gui=NONE     cterm=NONE
hi StorageClass       guisp=NONE      guifg=#A2A2A2  guibg=NONE     gui=NONE     cterm=NONE
hi Structure          guisp=NONE      guifg=#A2A2A2  guibg=NONE     gui=NONE     cterm=NONE
hi Typedef            guisp=NONE      guifg=#A2A2A2  guibg=NONE     gui=NONE     cterm=NONE
hi debugPC            guisp=NONE      guifg=NONE     guibg=#5E5E5E  gui=NONE     cterm=NONE
hi debugBreakpoint    guisp=NONE      guifg=#5E5E5E  guibg=#2E2E2E  gui=NONE     cterm=NONE

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
