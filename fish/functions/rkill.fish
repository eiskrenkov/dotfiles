function rkill -d "Kill Rails process"
  if not test -f tmp/pids/server.pid
    echo "There is no server.pid in tmp/pids"
  else
    set -l pid (cat tmp/pids/server.pid)
    kill -9 $pid
    echo "sigkill sent"
  end
end
