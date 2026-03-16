function ?? --description 'Quick Claude conversation'
    if test (count $argv) -eq 0
        echo "Usage: ?? <prompt>"
        return 1
    end

    set -l prompt $argv
    set -l session_id (uuidgen | tr '[:upper:]' '[:lower:]')

    claude -p --model haiku --session-id "$session_id" "$prompt"

    while true
        echo ""
        read -P ">> " followup

        if test -z "$followup"
            break
        end

        claude --model haiku -p --resume "$session_id" "$followup"
    end
end
