#!/bin/bash
set -evx

mkdir ~/.arion

# safety check
if [ ! -f ~/.arion/.arion.conf ]; then
  cp share/arion.conf.example ~/.arion/arion.conf
fi
