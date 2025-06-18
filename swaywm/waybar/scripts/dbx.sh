#!/bin/bash
echo -e $(/home/ajibola/bin/dropbox-cli status | sed -n 1p)