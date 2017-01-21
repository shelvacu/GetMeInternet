require "./GetMeInternet/*"
require "socket"
require "../lib/tuntap/src/tuntap.cr"

module GetMeInternet
  PORT = 5431
  SERVER_IP = "10.54.31.1"
  CLIENT_IP = "10.54.31.2"

  extend self
  
  def run(server_address : String? = nil)
    if server_address.nil?
      server_mode = true
      puts "Waiting for connection"
      socket = TCPServer.new("0.0.0.0", PORT).accept
    else
      server_mode = false
      socket = TCPSocket.new(server_address, PORT)
    end

    dev = Tuntap::Device.open flags: LibC::IfReqFlags::Tun | LibC::IfReqFlags::NoPi
    dev.up!

    my_ip = server_mode ? SERVER_IP : CLIENT_IP
    remote_ip = server_mode ? CLIENT_IP : SERVER_IP

    dev.add_address my_ip

    dev.add_route(
      destination: "10.54.31.0",
      gateway: my_ip,
      mask: "255.255.255.0",
      flags: LibC::RtEntryFlags.flags(Up, Gateway)
    )

    puts "Device is #{dev.name}"
    puts "      My IP address: #{my_ip}"
    puts "  Remote IP address: #{remote_ip}"
    puts "Now tunneling data. Hit Ctrl-C to stop."

    spawn do
      begin
        loop do
          packet = Bytes.new socket.read_bytes(UInt32)
          socket.read_fully packet

          info = Tuntap::IpPacket.new(frame: packet, has_pi: false)

          puts "-> #{info.size}B #{info.source_address} >> #{info.destination_address}"

          dev.write packet
        end
      rescue err
        puts err
        exit
      end
    end

    spawn do
      begin
        loop do
          packet = dev.read_packet

          puts "<- #{packet.size}B #{packet.source_address} >> #{packet.destination_address}"

          socket.write_bytes packet.size.to_u32
          socket.write packet.frame
        end
      end
    end
  end
end
