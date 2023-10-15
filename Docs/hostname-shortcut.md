# AppleNotSupprtingHostNameworkaround

## Obsolete

Here is a much simpler solution

[hostname-localhost.md](https://github.com/jaclu/AOK-Filesystem-Tools/blob/main/Docs/hostname-localhost.md)

## Introduction

Starting with iOS 17 Apple no longer supports the API that iSH uses
to retrieve hostname from iOS. Until that is resolved this is a
workaround to handle this.

First thing is to create a shortcut that writes hostname to a file that
iSH has access to, be it local, iCloud or other cloud storage does not
matter

If you have more than one device where you run iSH, it would propably
make most sense to use an iCloud file, the Shortcuts would normally be
synced to all your devices, and the replacement hostname program for iSH
is able to handle the case of multiple devices all reporting via the same
syncfile.

Second step is to create a Personal Automation, that runs this every time
iSH starts

Third step is to use a custom hostname bin that picks up the hostname
provided by the shortcut, placed early in your PATH, so that whenever
something runs hostname, this is what will be run.

## Shortcut Syncing Hostname

Create a Shortcut with the following items

- Get Device Details - Select Device Hostname
- Append to Text File - Append Device Hostname and select what file to use
make sure "Make New Line" is activated!

## Automation Personal

Create Personal Automation - App

- App - Choose iSH, click Done.
- Select "Run Immediately"
- Click Next
- Point it to the shortcut syncing hostname defined above

## Using this shortcut info

Make sure the sync file is accessible inside iSH, you probably will need
to mount that resource using something like `mount -t ios . /mnt/point`

Install a custom hostname, that uses the shortcut info, here is mine
[hostname using shortcut](https://raw.githubusercontent.com/jaclu/AOK-Filesystem-Tools/main/common_AOK/usr_local_bin/hostname)

First time you run my implementation it will complain that you need
to tell it where the file containing hostname fed by the shortcut is
located. Once that is done it acts as a normal hostname

As long as it is in something like /usr/local/bin and that is globbaly
added to PATH ash and bash will use the normal (h) correctly,
if you want to use hostname in your prompt.
