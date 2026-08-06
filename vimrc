" ~/.vimrc
" Leader key is ',' (set in the leader section below)

"general
"-------
syntax enable               " enable syntax processing
set tabstop=4               " number of visual spaces per TAB
set softtabstop=4           " number of spaces in tab when editing
set expandtab               " tabs are spaces
set mouse=a                 " enable mouse
set undofile                " Maintain undo history between sessions
" Keep persistent undo OUTSIDE any git repo. ~/.vim is a symlink into this
" dotfiles repo, so ~/.vim/undodir would put undo history — which records full
" file contents, including any secrets — under version control. ~/.cache is
" not tracked. Trailing // encodes the full path in the undofile name to avoid
" collisions.
if !isdirectory(expand('~/.cache/vim/undo'))
    call mkdir(expand('~/.cache/vim/undo'), 'p', 0700)
endif
set undodir=~/.cache/vim/undo//  " persistent undo, outside the repo

" Belt-and-braces: never write undo/swap/backup for secrets edited in place.
" `pass edit` opens a plaintext temp file in /dev/shm/pass.XXXX/ (tmpfs, which
" pass shreds) — but a persistent undofile would defeat that. Match tmpfs and
" pass temp dirs and disable every on-disk history for those buffers.
" Note: in autocmd patterns a single * does NOT cross /, so ** is required to
" match files nested inside the tmpfs / pass temp directories.
augroup secret_no_history
    autocmd!
    autocmd BufNewFile,BufReadPre /dev/shm/**,**/pass.*/** setlocal noundofile noswapfile nobackup nowritebackup
augroup END
set termguicolors

"ui
"--
set number              " show line numbers
set showcmd             " show command in bottom bar
"set cursorline          " highlight current line
filetype plugin indent on  " load filetype-specific plugin + indent files
set wildmenu            " visual autocomplete for command menu
set lazyredraw          " redraw only when we need to.
set showmatch           " highlight matching [{()}]
" Catppuccin theme from ~/.vim/colors
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
" Hand-rolled statusline: mode indicator, buffer number, paste/spell flags,
" file name, then right-aligned file type, line:column and percentage.
" The %#...# items switch highlight groups for colour.
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

"ii IRC mappings
"---------------
" Send the current line to an ii channel FIFO (used when composing IRC
" messages from within the ~/irc directories): w1=#archlinux, w2=#bash, w3=#f1
map w1 :.w >>\#archlinux/in
map w2 :.w >>\#bash/in
map w3 :.w >>\#f1/in

"beancount (vim-beancount plugin)
"--------------------------------
" vim's embedded python3 is the system python, which can't import beancount when
" it lives in a venv. Add that venv's site-packages to sys.path so account name
" omni-completion (insert-mode <C-x><C-o>) works. The version dir is derived from
" vim's own python, so a python point-bump self-heals once the venv is rebuilt.
augroup beancount_setup
    autocmd!
    if has('python3')
        autocmd FileType beancount python3 import sys, os; _bp = os.path.expanduser('~/venv/vizex/lib/python%d.%d/site-packages' % sys.version_info[:2]); (os.path.isdir(_bp) and _bp not in sys.path) and sys.path.insert(0, _bp)
    endif
    " Point completion at your ledger root so it sees every account across the
    " includes — set b:beancount_root to your own main file, e.g.:
    " autocmd BufRead,BufNewFile */ledger/*.beancount let b:beancount_root = expand('%:p:h') . '/main.beancount'
    " <leader>= aligns the commodity/amount column (works on a line or a selection).
    autocmd FileType beancount nnoremap <buffer> <leader>= :AlignCommodity<CR>
    autocmd FileType beancount xnoremap <buffer> <leader>= :AlignCommodity<CR>
augroup END

" jump to last edited position when reopening a file
au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g`\"" | endif
