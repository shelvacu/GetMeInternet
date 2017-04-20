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

sock.tcp_nodelay = true

recv_loop = spawn do
  loop do
    sock.flush
    line = sock.gets
    sock.flush
    if !line.nil?
      if line.starts_with?("PING")
        sock.puts "PO"+line[2..-1]
        sock.flush
      elsif line.starts_with?("PONG")
        puts Time.new.epoch_ms - line[4..-1].to_u64
      end
    end
    Fiber.yield
  end
end

send_loop = spawn do
  loop do
    sock.puts "PING#{Time.new.epoch_ms}"
    sock.flush
    sleep 1
  end
end

loop do
  Fiber.yield
end
