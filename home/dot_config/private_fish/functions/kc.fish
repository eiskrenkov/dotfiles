function kc -d "Switch between contexts"
  set context (kubectl config get-contexts --no-headers --output=name | fzf) || return

  kubectl config use-context $context
end
