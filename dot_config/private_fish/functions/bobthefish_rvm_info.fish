function bobthefish_rvm_info -S -d 'Current Ruby information from RVM'
  set -l version (rvm-prompt | awk -F '[/-]' '{print $2}')
  "\ue21e $version"
end
