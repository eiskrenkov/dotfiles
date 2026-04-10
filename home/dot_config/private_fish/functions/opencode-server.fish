function opencode-server --description "Manage opencode web server with Tailscale"
    set -l pidfile /tmp/opencode-server.pid
    set -l port 4096

    switch (string lower -- "$argv[1]")
        case start ''
            if test -f $pidfile; and kill -0 (cat $pidfile) 2>/dev/null
                echo "opencode-server is already running (pid "(cat $pidfile)")"
                return 1
            end

            opencode web --hostname 127.0.0.1 --port $port &
            echo $last_pid >$pidfile
            echo "Started opencode web (pid $last_pid)"

            sleep 1

            tailscale serve --bg http://127.0.0.1:$port
            echo "Tailscale serve configured on port $port"

        case stop
            if test -f $pidfile; and kill -0 (cat $pidfile) 2>/dev/null
                kill (cat $pidfile)
                rm -f $pidfile
                echo "Stopped opencode web"
            else
                echo "opencode-server is not running"
                rm -f $pidfile
            end

            tailscale serve reset
            echo "Tailscale serve removed"

        case status
            if test -f $pidfile; and kill -0 (cat $pidfile) 2>/dev/null
                echo "opencode-server is running (pid "(cat $pidfile)")"
                echo "Port: $port"
                tailscale serve status 2>/dev/null | string match -r 'https://\S+'
            else
                echo "opencode-server is not running"
                rm -f $pidfile
            end

        case open
            open "http://127.0.0.1:$port"
            echo "Opening http://127.0.0.1:$port in browser"

        case '*'
            echo "Usage: opencode-server [start|stop|status|open]"
            return 1
    end
end
