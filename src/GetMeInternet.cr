require "socket"
require "tuntap"
require "./sodium"
require "./GetMeInternet/*"
require "./benchmark"

macro log(msg)
  print Time.now
  print ": "
  if direction
    print "P->D "
  else
    print "P<-D "
  end
  puts {{msg}}
end

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
      trans = UDPTransportServer.new(
        {
          "port" => "5431"
        }
      )
    else
      server_mode = false
      trans = UDPTransportClient.new(
        {
          "server_addr" => server_address,
          "port" => "5431"
        }
      )
    end

    config.key!

    dev = Tuntap::Device.open(
      device_name: config.device_name,
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

    if !server_mode
      last_route = 0u64 #stop-gap
    end

    pipe_dev_loop = spawn do
      direction = true
      loop do
        begin
          trans.recv_packets(config.key!).each do |packet, route_id|
            last_route = route_id
            #TODO: verify sequence id to prevent duplicates.
            case packet.type
            when GetMeInternet::Packet::PacketType::Normal
              info = Tuntap::IpPacket.new(
                frame: packet.data,
                has_pi: false
              )

              log "-> #{info.size}B #{info.source_address}" +
                  " >> #{info.destination_address}" unless info.source_address == "0.0.0.0"

              dev.write packet.data
            when GetMeInternet::Packet::PacketType::Null
            # Do nothing
            else
              #TODO: Deal with other packet types
              STDERR.puts "WARNING: encountered packet we can't deal with yet"
            end
          end
          Fiber.yield
        rescue err
          log err
          exit
        end
      end
    end

    dev_pipe_loop = spawn do
      direction = false
      loop do
        begin
          #puts "D2P: loop iteration"
          #Can't send packets if we don't have a route to send them to.
          Benchmark.benchmark("dev->pipe outer") do
            inner_last_route = last_route
            if !inner_last_route.nil?
              ip_packet = dev.read_packet

              Benchmark.benchmark("dev->pipe inner") do
                #next if ip_packet.source_address == "0.0.0.0"
                
                log "<- #{ip_packet.size}B #{ip_packet.source_address}" +
                    " >> #{ip_packet.destination_address}" unless ip_packet.source_address == "0.0.0.0"
                
                gmi_packet = Packet.new(
                  Packet::PacketType::Normal,
                  sequence_inc += 1,
                  ip_packet.frame
                )

                enc_packet = EncryptedPacket.encrypt(
                  gmi_packet,
                  config.key!
                )

                trans.send_packet(enc_packet, inner_last_route.not_nil!)
              end
            end
          end
          Fiber.yield
        rescue err
          puts err
          exit
        end
      end
    end

  end
end
