# HostnameAlwaysLocalhost

## Introduction

Starting with iOS 17 Apple no longer supports the API that iSH uses
to retrieve hostname from iOS. Until that is resolved this is a
workaround to handle this.

## Set hostname

echo hostname > /etc/hostname

## Alternate hostname cmd

```shell
#!/bin/sh

cat /etc/hostname
```

Save this as `hostname` to somewhere in your PATH before /bin where the
normal hostname cmd is located, I would suggest /usr/local/bin for such
but you can use any location.
Then make it runable like this:

```shell
chmod 755 /path/to/alternate/hostname
```

You can replace the regular /bin/hostname with this, the drawback is that
next time /bin/hostname is upgraded, your alternate will be replaced.
The advantage is that there is no risk any script not having /usr/local/bin
in PATH will end up using "localhost" instead of the intended hostname.
