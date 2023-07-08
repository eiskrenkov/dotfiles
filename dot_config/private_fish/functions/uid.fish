function uid -d "Returns UUID"
  ruby -e "require 'securerandom'; puts SecureRandom.uuid"
end
