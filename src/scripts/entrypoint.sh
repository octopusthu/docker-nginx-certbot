#!/bin/sh

# When we get killed, kill all our children (o.O)
trap "exit" INT TERM
trap "kill 0" EXIT

# Source "util.sh" so we can have our nice tools
. $(cd $(dirname $0); pwd)/util.sh

# Immediately run auto_enable_configs so that nginx is in a runnable state
# This will temporarily disable any misconfigured servers.
auto_enable_configs

# Start up nginx, save PID so we can reload config inside of run_certbot.sh
nginx -g "daemon off;" &
export NGINX_PID=$!

# Lastly, run startup scripts
for f in /scripts/startup/*.sh; do
    if [ -x "$f" ]; then
        echo "Running startup script $f"
        $f
    fi
done
echo "Done with startup"

# Instead of trying to run `cron` or something like that, just sleep and run `certbot`.
while [ true ]; do
    echo "Run certbot"
    /scripts/run_certbot.sh

    echo "Sleeping for 1 week..."
    sleep 604810 &
    SLEEP_PID=$!

    # Wait on sleep so that when we get ctrl-c'ed it kills everything due to our trap
    wait "$SLEEP_PID"
done