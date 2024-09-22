#!/bin/bash
echo -e $($HOME/bin/dropbox-cli status | sed -n 1p)
