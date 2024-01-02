# InitOrder

`deploy_init_hints.sh`

Will drop in replacement init scripts, helping you to see what init scripts are used during different conditions, and in what order
It is not adviced to use on a "real" FS, since there will be a lot of cleanup to be done.
Better suited for a temp FS



## init order, Alpine

### Ash

/etc/profile is pulled I thought that was not the case

#### login shell

--- A  /etc/profile [42064] [/bin/ash] []
--- ~/.profile [42064] [/bin/ash] []
    setting ENV & SHINIT
--- ~/.env_init [42064] [/bin/ash] []
  probably trigered due to ENV [/root/.env_init]

#### interactive shell

--- ~/.env_init [43349] [/bin/ash] []
  probably trigered due to ENV [/root/.env_init]

### Bash

#### login shell

--- A  /etc/profile [46402] [/bin/bash] []
--- B1 ~/.bash_profile [46402] [/bin/bash] []

#### Interactive shell

---   /etc/bash/bashrc [47619] [bash] []
--- B  ~/.bashrc [47619] [bash] []

### Zsh

#### login shell

--- A!  /etc/zsh/zshenv [49469] [/bin/zsh] []
       testing with ENV [/root/.env_init]
       ZDOTDIR []
--- B  ~/.zshenv [49469] [/bin/zsh] []
--- C! /etc/zsh/zprofile [49469] [/bin/zsh] []
--- D  ~/.zprofile [49469] [/bin/zsh] []
--- E! /etc/zsh/zshrc (no login: C2) [49469] [/bin/zsh] []
       ZDOTDIR []
--- F  ~/.zshrc (no login: D) [49469] [/bin/zsh] []
--- G! /etc/zsh/zlogin [49469] [/bin/zsh] []
--- H  ~/.zlogin [49469] [/bin/zsh] []

#### Interactive shell

--- A!  /etc/zsh/zshenv [50098] [zsh] []
       testing with ENV [/root/.env_init]
       ZDOTDIR []
--- B  ~/.zshenv [50098] [zsh] []
--- E! /etc/zsh/zshrc (no login: C2) [50098] [zsh] []
       ZDOTDIR []
--- F  ~/.zshrc (no login: D) [50098] [zsh] []




## init order, Debian

### Bash

#### login shell

--- A  /etc/profile [53524] [/bin/bash] []
--- B1 ~/.bash_profile [53524] [/bin/bash] []

#### Interactive shell

--- A  /etc/bash.bashrc [65923] [bash] []
--- B  ~/.bashrc [65923] [bash] []

### Zsh

#### login shell

--- A!  /etc/zsh/zshenv [57463] [/bin/zsh] []
       testing with ENV [/root/.env_init]
       ZDOTDIR []
--- B  ~/.zshenv [57463] [/bin/zsh] []
--- C! /etc/zsh/zprofile [57463] [/bin/zsh] []
--- D  ~/.zprofile [57463] [/bin/zsh] []
--- E! /etc/zsh/zshrc (no login: C2) [57463] [/bin/zsh] []
       ZDOTDIR []
--- F  ~/.zshrc (no login: D) [57463] [/bin/zsh] []
--- G! /etc/zsh/zlogin [57463] [/bin/zsh] []
--- H  ~/.zlogin [57463] [/bin/zsh] []

#### Interactive shell


--- A!  /etc/zsh/zshenv [58406] [zsh] []
       testing with ENV [/root/.env_init]
       ZDOTDIR []
--- B  ~/.zshenv [58406] [zsh] []
--- E! /etc/zsh/zshrc (no login: C2) [58406] [zsh] []
       ZDOTDIR []
--- F  ~/.zshrc (no login: D) [58406] [zsh] []
