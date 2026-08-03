function ggrp --description "Pull current branch with rebase, then push"
  # Composed from the ggpull/ggpush aliases so the remote/branch logic stays in
  # one place. `&&` matters: a rebase that stops on conflicts must not push.
  ggpull --rebase && ggpush
end
