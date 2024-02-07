Starting with iOS 17 Apple no longer offers the iOS hostname to apps, instead just reporting "localhost"

Since it used to be provided via iOS, nobody has implemented any functinolly to change hostname within iSH. Hopefully that gets fixed at some point.

Here are some workarrounds to handle this. It can't solve all instances of `localhost` showing up, but it can make it much better.

Before starting to take action I would suggest to first browse through this document so that you have realistic expectations about if this will be worthwhile for you.

## Set hostname

Uppercase and dashes work, spaces cant be used. This has always worked, such as you can change this file. Up to this point iSH itself does not use it. So it has historically been a waste of time to bother to change this file.

``` shell
echo MyOwnIsh > /etc/hostname
```

## Alternate hostname cmd

On most normal Linuxes /usr/local/bin tends to be one of the first PATH items, for locally installed stuff to override the defaults. Alpine does things a bit differently, it puts it as the last item. This means that files put there won't override the defaults.

Therefore, replacing /bin/hostname directly would be the simplest solution. Then PATH becomes a non-issue.

``` shell
# Create alternate hostname command, and make it runable
echo "#!/bin/sh" >/usr/local/bin/hostname
echo "cat /etc/hostname" >/usr/local/bin/hostname
chmod 755 /usr/local/bin/hostname

#
# Replace original /bin/hostname with softlink to your alternate hostname
#
mv /bin/hostname /bin/hostname.org
ln -sf /usr/local/bin/hostname /bin/hostname|
```

At this point, if you type hostname at the prompt you should get the expected result.

## System tools

Most system tools get the hostname from the kernel, especially if they are compiled binaries. Currently, there is no way to change the kernel from reporting localhost.
In such cases, you can sometimes override the default behaviour if a specific tool allows for configuration of hostname, either in a config file, or by using command line parameters.

## Shell Prompts

By default, all the shells I am aware of use the kernel to get the hostname, so the built-in shortcuts to display the hostname can't be used.

Currently, The only way to get shell prompts to display the intended hostname is to replace the shell-specific shortcut for the hostname either with a fixed string or by running your alternate hostname cmd.

| shell | hostname shortcut to replacce
| - | - |
ash | `\h` | text ot
bash | `\h`
zsh  | `%m`

Method | Impacts
| - | - |
text | Simple solution, if you only have iSH installed on one device, this is sufficient. It will become an issue if you want to use your iSH env on multiple iSH devices, then you would have to remember to change the name again each time you sync your environment files to another system
$(/bin/hostname) | This way you abstract setting the hostname to a separate tool, and nothing in your shell setup is hardcoded to a specific hostname. You can copy your shell env to all your iSH devices and they will display their own hostname when the env files are updated to other nodes.<br> This will also work in the future when the default /bin/hostname can report the intended name. So it is Future proof, and you wont have to change it later on.<br><br> The CPU over head by running /bin/hostname in a shell vs using the shortcut and getting it directly from the kernel would not have any impact - how many times per second do you normally press Enter?


## Other general tools

### POSIX & Bash
Most general scripts use /bin/hostname, so they would typically show your intended hostname.

### Python
Python has built in support for reading the hostname from the kernel, so in most cases Python code would display localhost, but with Python you normally have source-code, so you could change places that really bother you to either display a static name, or displaying the output of /bin/hostname
