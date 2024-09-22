execute pathogen#infect()

"general
"-------
syntax enable               " enable syntax processing
set tabstop=4               " number of visual spaces per TAB
set softtabstop=4           " number of spaces in tab when editing
set expandtab               " tabs are spaces
set mouse=a                 " enable mouse
set undofile                " Maintain undo history between sessions
set undodir=~/.vim/undodir  " persistent undo
set termguicolors

"ui
"--
set number              " show line numbers
set showcmd             " show command in bottom bar
"set cursorline          " highlight current line
filetype indent on      " load filetype-specific indent files
set wildmenu            " visual autocomplete for command menu
set lazyredraw          " redraw only when we need to.
set showmatch           " highlight matching [{()}]
colorscheme catppuccin_macchiato
"search
"------
set incsearch           " search as characters are entered
set hlsearch            " highlight matches
" turn off search highlight
nnoremap <leader><space> :nohlsearch<CR>

"line movement
"---- --------
" move vertically by visual line
nnoremap j gj
nnoremap k gk

"leader
"------
let mapleader=","       " leader is comma
" jk is escape
inoremap jk <esc>
" save session
nnoremap <leader>ss :mksession<CR>
" Toggle spell checking on and off
nmap <silent> <leader>s :set spell!<CR>
" Set region to British English
set spelllang=en_gb
" activate spell check for composing emails in mutt
autocmd FileType mail set spell


"statusline
"----------
set laststatus=2
set statusline=
set statusline+=%#DiffAdd#%{(mode()=='n')?'\ \ NORMAL\ ':''}
set statusline+=%#DiffChange#%{(mode()=='i')?'\ \ INSERT\ ':''}
set statusline+=%#DiffDelete#%{(mode()=='r')?'\ \ RPLACE\ ':''}
set statusline+=%#Cursor#%{(mode()=='v')?'\ \ VISUAL\ ':''}
set statusline+=\ %n\           " buffer number
set statusline+=%#Visual#       " colour
set statusline+=%{&paste?'\ PASTE\ ':''}
set statusline+=%{&spell?'\ SPELL\ ':''}
set statusline+=%#CursorIM#     " colour
set statusline+=%R                        " readonly flag
set statusline+=%M                        " modified [+] flag
set statusline+=%#Cursor#               " colour
set statusline+=%#CursorLine#     " colour
set statusline+=\ %t\                   " short file name
set statusline+=%=                          " right align
set statusline+=%#CursorLine#   " colour
set statusline+=\ %Y\                   " file type
set statusline+=%#CursorIM#     " colour
set statusline+=\ %3l:%-2c\         " line + column
set statusline+=%#Cursor#       " colour
set statusline+=\ %3p%%\                " percentage

" mappings
map w1 :.w >>\#archlinux/in
map w2 :.w >>\#bash/in
map w3 :.w >>\#f1/in

" jump to last edied position
au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g`\"" | endif
