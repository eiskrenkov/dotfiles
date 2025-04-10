function gup -d "Switch to master, pull and get back"
  set previous_branch (current_branch)
  gco master
  ggpull
  gco $previous_branch
end
