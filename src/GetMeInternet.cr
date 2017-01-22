require "socket"
require "../lib/tuntap/src/tuntap.cr"
require "./sodium"
require "./GetMeInternet/*"

module GetMeInternet
  PORT = 5431
  SERVER_IP = "10.54.31.1"
  CLIENT_IP = "10.54.31.2"

  NONCE_LENGTH = Sodium::SecretBox::NONCE_BYTES

  extend self
  
  def run( config : Config, server_address : String? = nil)
    if server_address.nil?
      server_mode = true
      puts "Waiting for connection"
      socket = TCPServer.new("0.0.0.0", PORT).accept
    else
      server_mode = false
      socket = TCPSocket.new(server_address, PORT)
    end

    config.key!

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
        loop do #recv a packet from the pipe, put into tun device
          nonce = Bytes.new(NONCE_LENGTH)
          socket.read_fully nonce
          enc_packet = Bytes.new socket.read_bytes(UInt32)
          socket.read_fully enc_packet

          puts nonce.hexstring
          puts enc_packet.size
          
          packet = Sodium::SecretBox.decrypt(enc_packet, nonce, config.key!)

          puts packet.hexdump
          
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
        loop do #recv a packet from the tun device, put into the pipe
          packet = dev.read_packet

          puts "<- #{packet.size}B #{packet.source_address} >> #{packet.destination_address}"

          enc_packet, nonce = Sodium::SecretBox.encrypt(packet.frame, config.key!)

          puts nonce.hexstring
          puts enc_packet.size
          
          socket.write nonce
          socket.write_bytes enc_packet.size.to_u32
          socket.write enc_packet
        end
      end
    end
  end
end
