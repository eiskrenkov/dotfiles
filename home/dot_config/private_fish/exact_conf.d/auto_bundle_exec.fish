function define_bundle_context_functions --on-variable AUTO_BUNDLE_EXEC_COMMANDS
  for name in (string split : $AUTO_BUNDLE_EXEC_COMMANDS)
    function $name --wraps $name
      if test -e Gemfile -a (gem list "^($_)\$" -i) = true
        echo "Using Gemfile's $_"
        command bundle exec $_ $argv
      else
        echo "Using global $_"
        command $_ $argv
      end
    end
  end
end

set -gx AUTO_BUNDLE_EXEC_COMMANDS rails:rake:sidekiq:cap:rspec:rubocop
