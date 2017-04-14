require "socket"
if ARGV.size == 1
  server_mode = false
  server_addr = ARGV.first
else
  server_mode = true
end

if server_mode
  server = TCPServer.new("0.0.0.0",5431)
  sock = server.accept #accept a single client
else
  sock = TCPSocket.new(server_addr.not_nil!, 5431)
end

recv_loop = spawn do
  loop do
    line = sock.gets
    if !line.nil?
      if line.starts_with?("PING")
        sock.puts "PO"+line[2..-1]
      elsif line.starts_with?("PONG")
        puts Time.new.epoch_ms - line[4..-1].to_u64
      end
    end
    Fiber.yield
  end
end

send_loop = spawn do
  loop do
    sleep 1
    sock.puts "PING#{Time.new.epoch_ms}"
  end
end

loop do
  Fiber.yield
end
