require "socket"
require "./monotonic"
if ARGV.size == 1
  server_mode = false
  server_addr = ARGV.first
else
  server_mode = true
end

sock = UDPSocket.new
if server_mode
  sock.bind "0.0.0.0", 5431
  #wait for a message
  puts "waiting for message"
  _, client_addr = sock.receive
  puts "rcvd, starting"
else
  sock.connect server_addr.not_nil!, 5431
end

recv_loop = spawn do
  loop do
    sock.flush
    line, addr = sock.receive
    sock.flush
    #puts "rcvd #{line.inspect}"
    if !line.nil?
      if line.starts_with?("PING")
        sock.send "PO"+line[2..-1], addr
        sock.flush
      elsif line.starts_with?("PONG")
        puts Monotonic.time - line[4..-1].to_u64
      end
    end
    Fiber.yield
  end
end

send_loop = spawn do
  loop do
    if server_mode
      sock.send "PING#{Monotonic.time}", client_addr.not_nil!
    else
      sock.send "PING#{Monotonic.time}"
    end
    sock.flush
    #puts "sent PING"
    sleep 1
  end
end

loop do
  Fiber.yield
end
