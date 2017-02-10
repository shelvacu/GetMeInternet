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
  
  def run(config : Config, server_address : String? = nil)
    if server_address.nil?
      server_mode = true
      puts "Waiting for connection"
      #socket = TCPServer.new("0.0.0.0", PORT).accept
      trans = TCPTransportServer.new(
        {
          "listen_ports" => "5431"
        }
      )
    else
      server_mode = false
      #socket = TCPSocket.new(server_address, PORT)
      trans = TCPTransportClient.new(
        {
          "server_addr" => server_address,
          "port" => "5431"
        }
      )
    end

    config.key!

    dev = Tuntap::Device.open(
      flags: LibC::IfReqFlags::Tun | LibC::IfReqFlags::NoPi
    )
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

    sequence_inc = 1u64

    last_route : UInt64? = nil
    
    loop do
      puts "loop iteration"
      begin
        trans.recv_packets.each do |enc_pkt, route_id|
          last_route = route_id
          
          enc_pkt.decrypt(config.key!).each do |packet|
            #TODO: verify sequence id to prevent duplicates.
            case packet.type
            when GetMeInternet::Packet::PacketType::Normal
              info = Tuntap::IpPacket.new(frame: packet.data, has_pi: false)

              puts "-> #{info.size}B #{info.source_address} >> #{info.destination_address}"

              dev.write packet.data
            else
              #TODO: Deal with other packet types
            end
          end
        end

        #Can't send packets if we don't have a route to send them to.
        if !last_route.nil?
          ip_packet = dev.read_packet

          puts "<- #{ip_packet.size}B #{ip_packet.source_address} >> #{ip_packet.destination_address}"
          
          gmi_packet = Packet.new(
            Packet::PacketType::Normal,
            sequence_inc += 1,
            ip_packet.frame
          )

          enc_packet = EncryptedPacket.encrypt(
            gmi_packet,
            config.key!
          )

          puts "c"

          trans.send_packets([enc_packet], last_route)
        end
        Fiber.yield
      rescue err
        puts err
        exit
      end
    end
  end
end
