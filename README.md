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
```

## Vim
It is assumed that the Janus vim distribution is being used (see https://github.com/carlhuda/janus)

In this situation, `~/.vimrc` is owned by Janus and any additional
configuration is done in `~/.vimrc.before` and `~/.vimrc.after`.  So,
after installing Janus and cloning this repo, you'd use the following
command to include your settings:

```
ln -s ~/ldf-config/vimrc.after ~/.vimrc.after
```


