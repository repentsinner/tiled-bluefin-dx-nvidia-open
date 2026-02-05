#!/bin/bash
# Exit/logout script for Niri

if [ -n "$NIRI_SOCKET" ]; then
    niri msg action quit
else
    loginctl terminate-session self
fi
