#!/bin/bash
pkill -f 'quickshell.*shinbar' 2>/dev/null; sleep 0.3
qs -c ~/.config/quickshell/shinbar/ &
echo "shinbar ok"
