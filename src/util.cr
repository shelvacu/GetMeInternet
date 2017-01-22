require "option_parser"
require "./sodium"
require "./GetMeInternet/config.cr"

conf = GetMeInternet::Config.autoload

unless conf.key.nil?
  puts "WARNING: Key is already set. Continuing will overwrite the saved key. Enter to continue, Ctrl+C to stop"
  gets
end

key = Sodium::SecretBox.secure_random_key

conf.key = key

conf.save
