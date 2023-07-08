function psec -d "Parses passed seconds, prints human readable interpretation"
  ruby -e "require 'active_support/duration'; puts ActiveSupport::Duration.build(ARGV.first.to_i).inspect" $argv[1]
end
