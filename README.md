# ldf-config

Catch-all repo for sharing my config files.

Usage:
  
1. Check out

```
cd
git clone git@github.com:oldlance/ldf-config.git
```

2. Soft link

```
ln -s ~/ldf-config/<conf-file> ~/.<conf-file>
ln -s ~/ldf-config/appname/<conf-file> ~/.config/<appname>/.<conf-file>
```

## Vim

### Vanilla

I used the Janus distribution described below for years but have more recently started with the manual customisation route and installing packages manually. Packages that I typically install are:

- vimwiki
- nerdtree
- vim-pandoc
- vim-pandoc-syntax

My custom `vim/.vimrc` can be copied or soft-linked to `~/`.

I added the following vimwiki config to my `.vimrc`.  You may need to modify some of the paths.

`wiki.css` and `default.html` may be found in `vim/vimwiki` in this repo.

`wiki2html.sh` needs `git@github.com:oldlance/misaka_md2html.git`

```
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
```


### Janus

It is assumed that the Janus vim distribution is being used (see https://github.com/carlhuda/janus) which can be done as follows:

```
curl -L https://bit.ly/janus-bootstrap | bash
```

In this situation, `~/.vimrc` is owned by Janus and any additional configuration is done in `~/.vimrc.before` and `~/.vimrc.after`.  So, after installing Janus and cloning this repo, you'd use the following command to include your settings:

```
ln -s ~/ldf-config/vim/vimrc.after ~/.vimrc.after
```

## SQLFluff

```bash
ln -s ~/ldf-config/sqlfluff/sqlfluff ~/.sqlfluff
```

