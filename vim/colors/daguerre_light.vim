" Name: daguerre_light.vim
" Daguerre Light: strict grayscale (R=G=B throughout), no hue anywhere.
" See ~/.cfg-tzevaot/swaywm/daguerre/README.md and light/palette.md
" for the full palette and the cyan->link / orange->yellow hue collapse.

set background=light
hi clear

if exists('syntax on')
    syntax reset
endif

let g:colors_name='daguerre_light'
set t_Co=256

hi Normal             guisp=NONE      guifg=#0A0A0A  guibg=#FFFFFF  gui=NONE     cterm=NONE
hi Visual             guisp=NONE      guifg=NONE     guibg=#000000  gui=bold     cterm=bold
hi Conceal            guisp=NONE      guifg=#737373  guibg=NONE     gui=NONE     cterm=NONE
hi ColorColumn        guisp=NONE      guifg=NONE     guibg=#B2B2B2  gui=NONE     cterm=NONE
hi Cursor             guisp=NONE      guifg=#FFFFFF  guibg=#000000  gui=NONE     cterm=NONE
hi lCursor            guisp=NONE      guifg=#FFFFFF  guibg=#000000  gui=NONE     cterm=NONE
hi CursorIM           guisp=NONE      guifg=#FFFFFF  guibg=#000000  gui=NONE     cterm=NONE
hi CursorColumn       guisp=NONE      guifg=NONE     guibg=#E5E5E5  gui=NONE     cterm=NONE
hi CursorLine         guisp=NONE      guifg=NONE     guibg=#E5E5E5  gui=NONE     cterm=NONE
hi Directory          guisp=NONE      guifg=#191919  guibg=NONE     gui=NONE     cterm=NONE
hi DiffAdd            guisp=NONE      guifg=#FFFFFF  guibg=#4F4F4F  gui=NONE     cterm=NONE
hi DiffChange         guisp=NONE      guifg=#FFFFFF  guibg=#616161  gui=NONE     cterm=NONE
hi DiffDelete         guisp=NONE      guifg=#0A0A0A  guibg=#2B2B2B  gui=NONE     cterm=NONE
hi DiffText           guisp=NONE      guifg=#FFFFFF  guibg=#000000  gui=NONE     cterm=NONE
hi EndOfBuffer        guisp=NONE      guifg=NONE     guibg=NONE     gui=NONE     cterm=NONE
hi ErrorMsg           guisp=NONE      guifg=#2B2B2B  guibg=NONE     gui=bold,italic cterm=bold,italic
hi VertSplit          guisp=NONE      guifg=#858585  guibg=NONE     gui=NONE     cterm=NONE
hi Folded             guisp=NONE      guifg=#191919  guibg=#858585  gui=NONE     cterm=NONE
hi FoldColumn         guisp=NONE      guifg=#858585  guibg=#FFFFFF  gui=NONE     cterm=NONE
hi SignColumn         guisp=NONE      guifg=#858585  guibg=#FFFFFF  gui=NONE     cterm=NONE
hi IncSearch          guisp=NONE      guifg=#FFFFFF  guibg=#616161  gui=NONE     cterm=NONE
hi CursorLineNR       guisp=NONE      guifg=#000000  guibg=NONE     gui=NONE     cterm=NONE
hi LineNr             guisp=NONE      guifg=#858585  guibg=NONE     gui=NONE     cterm=NONE
hi MatchParen         guisp=NONE      guifg=#616161  guibg=NONE     gui=bold     cterm=bold
hi ModeMsg            guisp=NONE      guifg=#0A0A0A  guibg=NONE     gui=bold     cterm=bold
hi MoreMsg            guisp=NONE      guifg=#191919  guibg=NONE     gui=NONE     cterm=NONE
hi NonText            guisp=NONE      guifg=#858585  guibg=NONE     gui=NONE     cterm=NONE
hi Pmenu              guisp=NONE      guifg=#0A0A0A  guibg=#858585  gui=NONE     cterm=NONE
hi PmenuSel           guisp=NONE      guifg=#FFFFFF  guibg=#000000  gui=NONE     cterm=NONE
hi PmenuSbar          guisp=NONE      guifg=NONE     guibg=#858585  gui=NONE     cterm=NONE
hi PmenuThumb         guisp=NONE      guifg=NONE     guibg=#858585  gui=NONE     cterm=NONE
hi Question           guisp=NONE      guifg=#191919  guibg=NONE     gui=NONE     cterm=NONE
hi QuickFixLine       guisp=NONE      guifg=NONE     guibg=#858585  gui=bold     cterm=bold
hi Search             guisp=NONE      guifg=#FFFFFF  guibg=#000000  gui=bold     cterm=bold
hi SpecialKey         guisp=NONE      guifg=#858585  guibg=NONE     gui=NONE     cterm=NONE
hi StatusLine         guisp=NONE      guifg=#0A0A0A  guibg=#858585  gui=NONE     cterm=NONE
hi StatusLineNC       guisp=NONE      guifg=#858585  guibg=#858585  gui=NONE     cterm=NONE
hi TabLine            guisp=NONE      guifg=#858585  guibg=#858585  gui=NONE     cterm=NONE
hi TabLineFill        guisp=NONE      guifg=NONE     guibg=#858585  gui=NONE     cterm=NONE
hi TabLineSel         guisp=NONE      guifg=#4F4F4F  guibg=#FFFFFF  gui=bold     cterm=bold
hi Title              guisp=NONE      guifg=#191919  guibg=NONE     gui=NONE     cterm=NONE
hi VisualNOS          guisp=NONE      guifg=NONE     guibg=#000000  gui=bold     cterm=bold
hi WarningMsg         guisp=NONE      guifg=#616161  guibg=NONE     gui=NONE     cterm=NONE
hi WildMenu           guisp=NONE      guifg=NONE     guibg=#858585  gui=NONE     cterm=NONE
hi Comment            guisp=NONE      guifg=#737373  guibg=NONE     gui=NONE     cterm=NONE
hi Constant           guisp=NONE      guifg=#616161  guibg=NONE     gui=NONE     cterm=NONE
hi Identifier         guisp=NONE      guifg=#3D3D3D  guibg=NONE     gui=NONE     cterm=NONE
hi Statement          guisp=NONE      guifg=#3D3D3D  guibg=NONE     gui=NONE     cterm=NONE
hi PreProc            guisp=NONE      guifg=#191919  guibg=NONE     gui=NONE     cterm=NONE
hi Type               guisp=NONE      guifg=#191919  guibg=NONE     gui=NONE     cterm=NONE
hi Special            guisp=NONE      guifg=#191919  guibg=NONE     gui=NONE     cterm=NONE
hi Underlined         guisp=NONE      guifg=#0A0A0A  guibg=#FFFFFF  gui=underline cterm=underline
hi Error              guisp=NONE      guifg=#2B2B2B  guibg=NONE     gui=NONE     cterm=NONE
hi Todo               guisp=NONE      guifg=#FFFFFF  guibg=#616161  gui=NONE     cterm=NONE
hi String             guisp=NONE      guifg=#4F4F4F  guibg=NONE     gui=NONE     cterm=NONE
hi Character          guisp=NONE      guifg=#191919  guibg=NONE     gui=NONE     cterm=NONE
hi Number             guisp=NONE      guifg=#616161  guibg=NONE     gui=NONE     cterm=NONE
hi Boolean            guisp=NONE      guifg=#616161  guibg=NONE     gui=NONE     cterm=NONE
hi Float              guisp=NONE      guifg=#616161  guibg=NONE     gui=NONE     cterm=NONE
hi Function           guisp=NONE      guifg=#191919  guibg=NONE     gui=NONE     cterm=NONE
hi Conditional        guisp=NONE      guifg=#2B2B2B  guibg=NONE     gui=NONE     cterm=NONE
hi Repeat             guisp=NONE      guifg=#2B2B2B  guibg=NONE     gui=NONE     cterm=NONE
hi Label              guisp=NONE      guifg=#616161  guibg=NONE     gui=NONE     cterm=NONE
hi Operator           guisp=NONE      guifg=#191919  guibg=NONE     gui=NONE     cterm=NONE
hi Keyword            guisp=NONE      guifg=#3D3D3D  guibg=NONE     gui=NONE     cterm=NONE
hi Include            guisp=NONE      guifg=#3D3D3D  guibg=NONE     gui=NONE     cterm=NONE
hi StorageClass       guisp=NONE      guifg=#616161  guibg=NONE     gui=NONE     cterm=NONE
hi Structure          guisp=NONE      guifg=#616161  guibg=NONE     gui=NONE     cterm=NONE
hi Typedef            guisp=NONE      guifg=#616161  guibg=NONE     gui=NONE     cterm=NONE
hi debugPC            guisp=NONE      guifg=NONE     guibg=#858585  gui=NONE     cterm=NONE
hi debugBreakpoint    guisp=NONE      guifg=#858585  guibg=#FFFFFF  gui=NONE     cterm=NONE

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
