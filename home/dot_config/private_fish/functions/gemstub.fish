function gemstub -d "Stub/unstub local gem paths in .envrc"
    if test (count $argv) -lt 1
        echo "Usage: gemstub stub <gem-name> [<gem-name>...]"
        echo "       gemstub unstub"
        return 1
    end

    set -l command $argv[1]

    switch $command
        case stub
            if test (count $argv) -lt 2
                echo "Error: 'stub' command requires at least one gem name"
                return 1
            end

            # Process each gem name
            for gem_name in $argv[2..-1]
                # Convert gem-name to GEM_NAME_PATH
                set -l env_var_name (string upper (string replace -a '-' '_' $gem_name))_PATH
                set -l gem_path ~/tds/$gem_name
                set -l export_line "export $env_var_name=$gem_path"

                # Check if .envrc exists
                if not test -f .envrc
                    touch .envrc
                end

                # Check if this variable already exists (uncommented)
                if grep -q "^export $env_var_name=" .envrc
                    echo "$env_var_name already stubbed in .envrc"
                else
                    # Check if it exists but is commented out
                    if grep -q "^# export $env_var_name=" .envrc
                        # Uncomment it
                        sed -i '' "s|^# export $env_var_name=.*|$export_line|" .envrc
                        echo "Uncommented $env_var_name in .envrc"
                    else
                        # Add new line
                        echo $export_line >> .envrc
                        echo "Added $env_var_name to .envrc"
                    end
                end
            end

            # Run direnv allow
            direnv allow
            echo "Ran 'direnv allow'"

        case unstub
            # Comment out all *_PATH exports in .envrc
            if test -f .envrc
                sed -i '' 's|^export \([A-Z_]*_PATH=.*\)|# export \1|' .envrc
                echo "Commented out all *_PATH variables in .envrc"
                direnv allow
                echo "Ran 'direnv allow'"
            else
                echo "No .envrc file found"
                return 1
            end

        case '*'
            echo "Unknown command: $command"
            echo "Usage: gemstub stub <gem-name> [<gem-name>...]"
            echo "       gemstub unstub"
            return 1
    end
end
