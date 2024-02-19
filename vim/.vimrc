" Commands taken from https://www.shortcutfoo.com/blog/top-50-vim-configuration-options.

" Indenting
set autoindent |" : New lines inherit the indentation of previous lines.
set expandtab |": Convert tabs to spaces.
filetype indent on |": Enable indentation rules that are file-type specific.
set shiftround |": When shifting lines, round the indentation to the nearest multiple of "shiftwidth."
set shiftwidth=4 |": When shifting, indent using four spaces.
set smarttab |": Insert "tabstop" number of spaces when the "tab" key is pressed.
set tabstop=4 |": Indent using four spaces.

" Searching
set hlsearch |": Enable search highlighting.
set ignorecase |": Ignore case when searching.
set incsearch |": Incremental search that shows partial matches.
set smartcase |": Automatically switch search to case-sensitive when search query contains an uppercase letter.

" Performance options
set complete-=i |": Limit the files searched for auto-completes.
set lazyredraw |": Don't update screen during macro and script execution.

" Test rendering options
set display+=lastline |": Always try to show a paragraph's last line.
set encoding=utf-8 |": Use an encoding that supports unicode.
set linebreak |": Avoid wrapping a line in the middle of a word.
set scrolloff=1 |": The number of screen lines to keep above and below the cursor.
set sidescrolloff=5 |": The number of screen columns to keep to the left and right of the cursor.
syntax enable |": Enable syntax highlighting.
set wrap |": Enable line wrapping.

" User interface options
set laststatus=2 |": Always display the status bar.
set ruler |": Always show cursor position.
set wildmenu |": Display command line's tab complete options as a menu.
set tabpagemax=50 |": Maximum number of tab pages that can be opened from the command line.
colorscheme industry |": Change color scheme.
set cursorline |": Highlight the line currently under cursor.
set number |": Show line numbers on the sidebar.
set relativenumber |": Show line number on the current line and relative numbers on all other lines.
set noerrorbells |": Disable beep on errors.
set visualbell |": Flash the screen instead of beeping on errors.
set mouse=a |": Enable mouse for scrolling and resizing.
set title |": Set the window's title, reflecting the file currently being edited.
set background=dark |": Use colors that suit a dark background.
set colorcolumn=88 |": create a highlighted vertical bar at column number n

" Cold folding settings 
set foldmethod=indent |": Fold based on indention levels.
set foldnestmax=3 |": Only fold up to three nested levels.
set nofoldenable |": Disable folding by default.

" Miscellaneous options

set autoread |": Automatically re-read files if unmodified inside Vim.
set backspace=indent,eol,start |": Allow backspacing over indention, line breaks and insertion start.
set backupdir=~/.cache/vim |": Directory to store backup files.
set confirm |": Display a confirmation dialog when closing an unsaved file.
set dir=~/.cache/vim |": Directory to store swap files.
set formatoptions+=j |": Delete comment characters when joining lines.
set hidden |": Hide files in the background instead of closing them.
set history=1000 |": Increase the undo limit.
set nomodeline |": Ignore file's mode lines; use vimrc configurations instead.
set noswapfile |": Disable swap files.
set nrformats-=octal |": Interpret octal as decimal when incrementing numbers.
set shell=/bin/sh |": The shell used to execute commands.
set spell |": Enable spellchecking.
set wildignore+=.pyc,.swp |": Ignore files matching these patterns when opening files based on a glob pattern.

" Options to allow VimWiki to work
set nocompatible
filetype plugin on
syntax on

let g:vimwiki_list = [{'path': '$HOME/SyncThing/vimwiki/',
                      \ 'path_html': '$HOME/SyncThing/vw-html',
                      \ 'auto_toc': 0,
                      \ 'syntax': 'markdown',
                      \ 'ext': '.md',
                      \ 'css_name': 'wiki.css',
                      \ 'custom_wiki2html': '$HOME/bin/wiki2html.sh',
                      \ 'template_path': '$HOME/vimwiki',
                      \ 'template_default': 'default',
                      \ 'template_ext': '.html' }]

" Options to integrate vimwiki with pandoc
augroup pandoc_syntax
  autocmd! FileType vimwiki set syntax=markdown.pandoc
augroup END



" Start NERDTree when Vim starts with a directory argument.
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 1 && isdirectory(argv()[0]) && !exists('s:std_in') |
    \ execute 'NERDTree' argv()[0] | wincmd p | enew | execute 'cd '.argv()[0] | endif
