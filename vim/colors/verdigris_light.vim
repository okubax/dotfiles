" Name: verdigris_light.vim
" Verdigris Light: an original oxidized-copper/patina palette, built from scratch.
" See ~/.cfg-tzevaot/swaywm/verdigris/README.md and light/palette.md
" for the full palette and provenance.

set background=light
hi clear

if exists('syntax on')
    syntax reset
endif

let g:colors_name='verdigris_light'
set t_Co=256

hi Normal             guisp=NONE      guifg=#24312B  guibg=#F4EFE6  gui=NONE     cterm=NONE
hi Visual             guisp=NONE      guifg=NONE     guibg=#B85E24  gui=bold     cterm=bold
hi Conceal            guisp=NONE      guifg=#5C6F66  guibg=NONE     gui=NONE     cterm=NONE
hi ColorColumn        guisp=NONE      guifg=NONE     guibg=#CBBFA3  gui=NONE     cterm=NONE
hi Cursor             guisp=NONE      guifg=#F4EFE6  guibg=#B85E24  gui=NONE     cterm=NONE
hi lCursor            guisp=NONE      guifg=#F4EFE6  guibg=#B85E24  gui=NONE     cterm=NONE
hi CursorIM           guisp=NONE      guifg=#F4EFE6  guibg=#B85E24  gui=NONE     cterm=NONE
hi CursorColumn       guisp=NONE      guifg=NONE     guibg=#EAE2D3  gui=NONE     cterm=NONE
hi CursorLine         guisp=NONE      guifg=NONE     guibg=#EAE2D3  gui=NONE     cterm=NONE
hi Directory          guisp=NONE      guifg=#1F7A70  guibg=NONE     gui=NONE     cterm=NONE
hi DiffAdd            guisp=NONE      guifg=#F4EFE6  guibg=#4C7A3A  gui=NONE     cterm=NONE
hi DiffChange         guisp=NONE      guifg=#F4EFE6  guibg=#96751C  gui=NONE     cterm=NONE
hi DiffDelete         guisp=NONE      guifg=#24312B  guibg=#A8402A  gui=NONE     cterm=NONE
hi DiffText           guisp=NONE      guifg=#F4EFE6  guibg=#B85E24  gui=NONE     cterm=NONE
hi EndOfBuffer        guisp=NONE      guifg=NONE     guibg=NONE     gui=NONE     cterm=NONE
hi ErrorMsg           guisp=NONE      guifg=#A8402A  guibg=NONE     gui=bold,italic cterm=bold,italic
hi VertSplit          guisp=NONE      guifg=#8FA096  guibg=NONE     gui=NONE     cterm=NONE
hi Folded             guisp=NONE      guifg=#1F7A70  guibg=#8FA096  gui=NONE     cterm=NONE
hi FoldColumn         guisp=NONE      guifg=#8FA096  guibg=#F4EFE6  gui=NONE     cterm=NONE
hi SignColumn         guisp=NONE      guifg=#8FA096  guibg=#F4EFE6  gui=NONE     cterm=NONE
hi IncSearch          guisp=NONE      guifg=#F4EFE6  guibg=#96751C  gui=NONE     cterm=NONE
hi CursorLineNR       guisp=NONE      guifg=#B85E24  guibg=NONE     gui=NONE     cterm=NONE
hi LineNr             guisp=NONE      guifg=#8FA096  guibg=NONE     gui=NONE     cterm=NONE
hi MatchParen         guisp=NONE      guifg=#96751C  guibg=NONE     gui=bold     cterm=bold
hi ModeMsg            guisp=NONE      guifg=#24312B  guibg=NONE     gui=bold     cterm=bold
hi MoreMsg            guisp=NONE      guifg=#1F7A70  guibg=NONE     gui=NONE     cterm=NONE
hi NonText            guisp=NONE      guifg=#8FA096  guibg=NONE     gui=NONE     cterm=NONE
hi Pmenu              guisp=NONE      guifg=#24312B  guibg=#8FA096  gui=NONE     cterm=NONE
hi PmenuSel           guisp=NONE      guifg=#F4EFE6  guibg=#B85E24  gui=NONE     cterm=NONE
hi PmenuSbar          guisp=NONE      guifg=NONE     guibg=#8FA096  gui=NONE     cterm=NONE
hi PmenuThumb         guisp=NONE      guifg=NONE     guibg=#8FA096  gui=NONE     cterm=NONE
hi Question           guisp=NONE      guifg=#1F7A70  guibg=NONE     gui=NONE     cterm=NONE
hi QuickFixLine       guisp=NONE      guifg=NONE     guibg=#8FA096  gui=bold     cterm=bold
hi Search             guisp=NONE      guifg=#F4EFE6  guibg=#B85E24  gui=bold     cterm=bold
hi SpecialKey         guisp=NONE      guifg=#8FA096  guibg=NONE     gui=NONE     cterm=NONE
hi StatusLine         guisp=NONE      guifg=#24312B  guibg=#8FA096  gui=NONE     cterm=NONE
hi StatusLineNC       guisp=NONE      guifg=#8FA096  guibg=#8FA096  gui=NONE     cterm=NONE
hi TabLine            guisp=NONE      guifg=#8FA096  guibg=#8FA096  gui=NONE     cterm=NONE
hi TabLineFill        guisp=NONE      guifg=NONE     guibg=#8FA096  gui=NONE     cterm=NONE
hi TabLineSel         guisp=NONE      guifg=#4C7A3A  guibg=#F4EFE6  gui=bold     cterm=bold
hi Title              guisp=NONE      guifg=#1F7A70  guibg=NONE     gui=NONE     cterm=NONE
hi VisualNOS          guisp=NONE      guifg=NONE     guibg=#B85E24  gui=bold     cterm=bold
hi WarningMsg         guisp=NONE      guifg=#96751C  guibg=NONE     gui=NONE     cterm=NONE
hi WildMenu           guisp=NONE      guifg=NONE     guibg=#8FA096  gui=NONE     cterm=NONE
hi Comment            guisp=NONE      guifg=#5C6F66  guibg=NONE     gui=NONE     cterm=NONE
hi Constant           guisp=NONE      guifg=#96751C  guibg=NONE     gui=NONE     cterm=NONE
hi Identifier         guisp=NONE      guifg=#7A4F76  guibg=NONE     gui=NONE     cterm=NONE
hi Statement          guisp=NONE      guifg=#7A4F76  guibg=NONE     gui=NONE     cterm=NONE
hi PreProc            guisp=NONE      guifg=#1F7A70  guibg=NONE     gui=NONE     cterm=NONE
hi Type               guisp=NONE      guifg=#1F7A70  guibg=NONE     gui=NONE     cterm=NONE
hi Special            guisp=NONE      guifg=#1F7A70  guibg=NONE     gui=NONE     cterm=NONE
hi Underlined         guisp=NONE      guifg=#24312B  guibg=#F4EFE6  gui=underline cterm=underline
hi Error              guisp=NONE      guifg=#A8402A  guibg=NONE     gui=NONE     cterm=NONE
hi Todo               guisp=NONE      guifg=#F4EFE6  guibg=#96751C  gui=NONE     cterm=NONE
hi String             guisp=NONE      guifg=#4C7A3A  guibg=NONE     gui=NONE     cterm=NONE
hi Character          guisp=NONE      guifg=#1F7A70  guibg=NONE     gui=NONE     cterm=NONE
hi Number             guisp=NONE      guifg=#96751C  guibg=NONE     gui=NONE     cterm=NONE
hi Boolean            guisp=NONE      guifg=#96751C  guibg=NONE     gui=NONE     cterm=NONE
hi Float              guisp=NONE      guifg=#96751C  guibg=NONE     gui=NONE     cterm=NONE
hi Function           guisp=NONE      guifg=#1F7A70  guibg=NONE     gui=NONE     cterm=NONE
hi Conditional        guisp=NONE      guifg=#A8402A  guibg=NONE     gui=NONE     cterm=NONE
hi Repeat             guisp=NONE      guifg=#A8402A  guibg=NONE     gui=NONE     cterm=NONE
hi Label              guisp=NONE      guifg=#96751C  guibg=NONE     gui=NONE     cterm=NONE
hi Operator           guisp=NONE      guifg=#1F7A70  guibg=NONE     gui=NONE     cterm=NONE
hi Keyword            guisp=NONE      guifg=#7A4F76  guibg=NONE     gui=NONE     cterm=NONE
hi Include            guisp=NONE      guifg=#7A4F76  guibg=NONE     gui=NONE     cterm=NONE
hi StorageClass       guisp=NONE      guifg=#96751C  guibg=NONE     gui=NONE     cterm=NONE
hi Structure          guisp=NONE      guifg=#96751C  guibg=NONE     gui=NONE     cterm=NONE
hi Typedef            guisp=NONE      guifg=#96751C  guibg=NONE     gui=NONE     cterm=NONE
hi debugPC            guisp=NONE      guifg=NONE     guibg=#8FA096  gui=NONE     cterm=NONE
hi debugBreakpoint    guisp=NONE      guifg=#8FA096  guibg=#F4EFE6  gui=NONE     cterm=NONE

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
