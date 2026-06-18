#!/bin/sh
set -e

# //go:embed all:web (main.go:8) requires ./web to exist at compile time.
# In dev, the real UI is served by rsbuild on host (port 43210), so a
# placeholder file is enough to keep the embed happy.
if [ ! -d /src/web ] || [ -z "$(ls -A /src/web 2>/dev/null)" ]; then
    mkdir -p /src/web
    cat > /src/web/index.html <<'HTML'
<!DOCTYPE html>
<html><body>
<h1>Seanime dev backend</h1>
<p>UI dev server: <a href="http://localhost:43210">http://localhost:43210</a></p>
</body></html>
HTML
fi

mkdir -p /dev-data

exec "$@"
