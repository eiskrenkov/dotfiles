function adb -d "Run the adb pointed to by \$UNITY_ADB (set by direnv), falling back to PATH"
  if set -q UNITY_ADB; and test -x "$UNITY_ADB"
    command "$UNITY_ADB" $argv
  else if command -q adb
    command adb $argv
  else if set -q UNITY_ADB
    echo "adb: \$UNITY_ADB is set but not executable: $UNITY_ADB" >&2
    return 127
  else
    echo "adb: no \$UNITY_ADB set (is direnv allowed in this directory?) and no adb on PATH" >&2
    return 127
  end
end
