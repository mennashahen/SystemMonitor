#!/bin/bash
/bin/bash /app/scripts/monitor.sh &
cd /app/web
python3 -m http.server 8000