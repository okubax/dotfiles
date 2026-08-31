" Name: verdigris_dark.vim
" Verdigris Dark: an original oxidized-copper/patina palette, built from scratch.
" See ~/.cfg-tzevaot/swaywm/verdigris/README.md and dark/palette.md
" for the full palette and provenance.

set background=dark
hi clear

if exists('syntax on')
    syntax reset
endif

let g:colors_name='verdigris_dark'
set t_Co=256

hi Normal             guisp=NONE      guifg=#DCEDE8  guibg=#14201E  gui=NONE     cterm=NONE
hi Visual             guisp=NONE      guifg=NONE     guibg=#E08D4B  gui=bold     cterm=bold
hi Conceal            guisp=NONE      guifg=#7FA69C  guibg=NONE     gui=NONE     cterm=NONE
hi ColorColumn        guisp=NONE      guifg=NONE     guibg=#2C423D  gui=NONE     cterm=NONE
hi Cursor             guisp=NONE      guifg=#14201E  guibg=#E08D4B  gui=NONE     cterm=NONE
hi lCursor            guisp=NONE      guifg=#14201E  guibg=#E08D4B  gui=NONE     cterm=NONE
hi CursorIM           guisp=NONE      guifg=#14201E  guibg=#E08D4B  gui=NONE     cterm=NONE
hi CursorColumn       guisp=NONE      guifg=NONE     guibg=#1B2A27  gui=NONE     cterm=NONE
hi CursorLine         guisp=NONE      guifg=NONE     guibg=#1B2A27  gui=NONE     cterm=NONE
hi Directory          guisp=NONE      guifg=#4FB3A9  guibg=NONE     gui=NONE     cterm=NONE
hi DiffAdd            guisp=NONE      guifg=#14201E  guibg=#7FB069  gui=NONE     cterm=NONE
hi DiffChange         guisp=NONE      guifg=#14201E  guibg=#E0B84B  gui=NONE     cterm=NONE
hi DiffDelete         guisp=NONE      guifg=#DCEDE8  guibg=#D9634B  gui=NONE     cterm=NONE
hi DiffText           guisp=NONE      guifg=#14201E  guibg=#E08D4B  gui=NONE     cterm=NONE
hi EndOfBuffer        guisp=NONE      guifg=NONE     guibg=NONE     gui=NONE     cterm=NONE
hi ErrorMsg           guisp=NONE      guifg=#D9634B  guibg=NONE     gui=bold,italic cterm=bold,italic
hi VertSplit          guisp=NONE      guifg=#4C6B64  guibg=NONE     gui=NONE     cterm=NONE
hi Folded             guisp=NONE      guifg=#4FB3A9  guibg=#4C6B64  gui=NONE     cterm=NONE
hi FoldColumn         guisp=NONE      guifg=#4C6B64  guibg=#14201E  gui=NONE     cterm=NONE
hi SignColumn         guisp=NONE      guifg=#4C6B64  guibg=#14201E  gui=NONE     cterm=NONE
hi IncSearch          guisp=NONE      guifg=#14201E  guibg=#E0B84B  gui=NONE     cterm=NONE
hi CursorLineNR       guisp=NONE      guifg=#E08D4B  guibg=NONE     gui=NONE     cterm=NONE
hi LineNr             guisp=NONE      guifg=#4C6B64  guibg=NONE     gui=NONE     cterm=NONE
hi MatchParen         guisp=NONE      guifg=#E0B84B  guibg=NONE     gui=bold     cterm=bold
hi ModeMsg            guisp=NONE      guifg=#DCEDE8  guibg=NONE     gui=bold     cterm=bold
hi MoreMsg            guisp=NONE      guifg=#4FB3A9  guibg=NONE     gui=NONE     cterm=NONE
hi NonText            guisp=NONE      guifg=#4C6B64  guibg=NONE     gui=NONE     cterm=NONE
hi Pmenu              guisp=NONE      guifg=#DCEDE8  guibg=#4C6B64  gui=NONE     cterm=NONE
hi PmenuSel           guisp=NONE      guifg=#14201E  guibg=#E08D4B  gui=NONE     cterm=NONE
hi PmenuSbar          guisp=NONE      guifg=NONE     guibg=#4C6B64  gui=NONE     cterm=NONE
hi PmenuThumb         guisp=NONE      guifg=NONE     guibg=#4C6B64  gui=NONE     cterm=NONE
hi Question           guisp=NONE      guifg=#4FB3A9  guibg=NONE     gui=NONE     cterm=NONE
hi QuickFixLine       guisp=NONE      guifg=NONE     guibg=#4C6B64  gui=bold     cterm=bold
hi Search             guisp=NONE      guifg=#14201E  guibg=#E08D4B  gui=bold     cterm=bold
hi SpecialKey         guisp=NONE      guifg=#4C6B64  guibg=NONE     gui=NONE     cterm=NONE
hi StatusLine         guisp=NONE      guifg=#DCEDE8  guibg=#4C6B64  gui=NONE     cterm=NONE
hi StatusLineNC       guisp=NONE      guifg=#4C6B64  guibg=#4C6B64  gui=NONE     cterm=NONE
hi TabLine            guisp=NONE      guifg=#4C6B64  guibg=#4C6B64  gui=NONE     cterm=NONE
hi TabLineFill        guisp=NONE      guifg=NONE     guibg=#4C6B64  gui=NONE     cterm=NONE
hi TabLineSel         guisp=NONE      guifg=#7FB069  guibg=#14201E  gui=bold     cterm=bold
hi Title              guisp=NONE      guifg=#4FB3A9  guibg=NONE     gui=NONE     cterm=NONE
hi VisualNOS          guisp=NONE      guifg=NONE     guibg=#E08D4B  gui=bold     cterm=bold
hi WarningMsg         guisp=NONE      guifg=#E0B84B  guibg=NONE     gui=NONE     cterm=NONE
hi WildMenu           guisp=NONE      guifg=NONE     guibg=#4C6B64  gui=NONE     cterm=NONE
hi Comment            guisp=NONE      guifg=#7FA69C  guibg=NONE     gui=NONE     cterm=NONE
hi Constant           guisp=NONE      guifg=#E0B84B  guibg=NONE     gui=NONE     cterm=NONE
hi Identifier         guisp=NONE      guifg=#A97CA5  guibg=NONE     gui=NONE     cterm=NONE
hi Statement          guisp=NONE      guifg=#A97CA5  guibg=NONE     gui=NONE     cterm=NONE
hi PreProc            guisp=NONE      guifg=#4FB3A9  guibg=NONE     gui=NONE     cterm=NONE
hi Type               guisp=NONE      guifg=#4FB3A9  guibg=NONE     gui=NONE     cterm=NONE
hi Special            guisp=NONE      guifg=#4FB3A9  guibg=NONE     gui=NONE     cterm=NONE
hi Underlined         guisp=NONE      guifg=#DCEDE8  guibg=#14201E  gui=underline cterm=underline
hi Error              guisp=NONE      guifg=#D9634B  guibg=NONE     gui=NONE     cterm=NONE
hi Todo               guisp=NONE      guifg=#14201E  guibg=#E0B84B  gui=NONE     cterm=NONE
hi String             guisp=NONE      guifg=#7FB069  guibg=NONE     gui=NONE     cterm=NONE
hi Character          guisp=NONE      guifg=#4FB3A9  guibg=NONE     gui=NONE     cterm=NONE
hi Number             guisp=NONE      guifg=#E0B84B  guibg=NONE     gui=NONE     cterm=NONE
hi Boolean            guisp=NONE      guifg=#E0B84B  guibg=NONE     gui=NONE     cterm=NONE
hi Float              guisp=NONE      guifg=#E0B84B  guibg=NONE     gui=NONE     cterm=NONE
hi Function           guisp=NONE      guifg=#4FB3A9  guibg=NONE     gui=NONE     cterm=NONE
hi Conditional        guisp=NONE      guifg=#D9634B  guibg=NONE     gui=NONE     cterm=NONE
hi Repeat             guisp=NONE      guifg=#D9634B  guibg=NONE     gui=NONE     cterm=NONE
hi Label              guisp=NONE      guifg=#E0B84B  guibg=NONE     gui=NONE     cterm=NONE
hi Operator           guisp=NONE      guifg=#4FB3A9  guibg=NONE     gui=NONE     cterm=NONE
hi Keyword            guisp=NONE      guifg=#A97CA5  guibg=NONE     gui=NONE     cterm=NONE
hi Include            guisp=NONE      guifg=#A97CA5  guibg=NONE     gui=NONE     cterm=NONE
hi StorageClass       guisp=NONE      guifg=#E0B84B  guibg=NONE     gui=NONE     cterm=NONE
hi Structure          guisp=NONE      guifg=#E0B84B  guibg=NONE     gui=NONE     cterm=NONE
hi Typedef            guisp=NONE      guifg=#E0B84B  guibg=NONE     gui=NONE     cterm=NONE
hi debugPC            guisp=NONE      guifg=NONE     guibg=#4C6B64  gui=NONE     cterm=NONE
hi debugBreakpoint    guisp=NONE      guifg=#4C6B64  guibg=#14201E  gui=NONE     cterm=NONE

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
