require "./GetMeInternet"

if ARGV[0].blank? || {"-h","--help","-?"}.includes? ARGV[0]
  puts "Usage: client {server-address}"
end

GetMeInternet.run(GetMeInternet::Config.autoload, ARGV[0])

sleep