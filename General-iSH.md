# General iSH hints

## Trouble cloning git repos

Doing `git config --global pack.threads "1"` sets up you iSH environment
to work with git repositories

## Python

First do `apk add py3-pip` After that you have a basic python3 environment.
No need to separately install python3, since it is pulled in as a
dependency.

Rather than doing the usual `pip install xxx` which often fails on iSH
especially if the package needs to compile something,
first try

```apk search py3- | grep xxx```

and if found do the matching  `apk add` for that package. 
If what you are looking for is available as an apk package it will work, 
so this is the prefered way to meet dependencies.

If you are lucky `pip install xxx` will work, but dont have too high
expectations...
