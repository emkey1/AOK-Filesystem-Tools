#!/bin/sh
apt clean

rm -rf /var/lib/apt/lists/*
rm -rf /var/cache/debconf/*
rm -rf /var/cache/man/*

rm -f /var/log/alternatives.log
rm -rf /var/log/apt
rm -f /var/log/dpkg.log

rm -rf /tmp/*
