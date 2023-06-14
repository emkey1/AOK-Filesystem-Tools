# Nav-Key handling

## Propagating Nav-Key

If you want your nav-key setting to be picked up on remote nodes and used
when setting up tmux over there, you can do something like this in your
iPad init file

```bash
nav_key="$(cat /etc/opt/tmux_nav_key 2>/dev/null)"
[ -n "$nav_key" ] && export ISH_NAV_KEY="$nav_key"
```

In order for this setting to propagate across ssh links, you need to
change two more files. If you intend to jump from remote_a to remote_b
and so on, the below change needs to be applied to each relevant host.

### Client end: ~/.ssh/config

Add this line

```ssh
SendEnv ISH_NAV_KEY
```

### Server end:  /etc/ssh/sshd_config

Add this line

```ssh
AcceptEnv ISH_NAV_KEY
```

If you want a more generic setting you could use `AcceptEnv ISH_*`
Then restart sshd on that node, so that the change takes effect.

## Remote nodes

### Simple aproach

In order for the remote node to use your iPad nav key
setting, copy the file /etc/opt/tmux_nav_key_handling from your iPad
to some suitable location on the remote host. This file would need to be
updated if you change your nav_key.
Then add this snippet into your remote tmux config

```tmux
#
#  if tmux is started via ssh or mosh from the iSH console,
#  then use the iSH nav-key
#
run-shell "[ -n "$ISH_NAV_KEY" ] && tmux source /path/to/tmux_nav_key_handling"
```

### Dynamic handling

If you want somewhat over the top dynamic handling, so that the remote
tmux will honour the actual current navkey setting, you can check
![jaclu/my_tmux_conf](https://github.com/jaclu/my_tmux_conf)

the relevant stuff is in the file `ish_console.py`
