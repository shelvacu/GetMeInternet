require "./GetMeInternet"

if ARGV.empty? || {"-h","--help","-?"}.includes? ARGV[0]
  puts "Usage: client {server-address}"
  exit
end

GetMeInternet.run(GetMeInternet::Config.autoload, ARGV[0])

sleep
