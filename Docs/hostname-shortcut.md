# AppleNotSupprtingHostNameWorkArround

## Introduction

Starting with iOS 17 Apple no longer supports the API that iSH uses
to retrieve hostname from iOS. Until that is resolved this is a
workaround to handle this.

First thing is to create a shortcut that writes hostname to a file that
iSH has access to, be it local, iCloud or other cloud storage does not matter

If you have more than one device where you run iSH, it would propably
make most sense to use an iCloud file, the Shortcuts would normally be
synced to all your devices, and the replacement hostname program for iSH
is able to handle the case of multiple devices all reporting via the same
syncfile.

Second step is to create a Personal Automation, that runs this every time
iSH starts

Third step is to use a custom hostname bin, placed early in your PATH,
so that whenever something runs hostname, this is what will be run.

## Shortcut Syncing Hostname

Create a Shortcut with the following items

Get Deice Details - Select Device Hostname

Append to Text File - Append Device Hostname and select what file to use
make sure "Make New Line" is activated!

## Automation Personal

Create Personal Automation App
App - Choose iSH, click Done.
Select "Run Immediately"
Click Next
Point it to the shortcut syncing hostname defined above

## Using this shortcut info

Install a custom hostname, that uses the shortcut info, here is mine
