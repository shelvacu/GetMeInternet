require "./transport"
require "../buffer_pair"

module GetMeInternet
  class TCPTransportServer
    include TransportServer

    @bind_addr : String
    @listen_ports : Array(UInt16)

    alias ClientData = NamedTuple(sock: TCPSocket, bp: BufferPair)

    def self.name
      return "tcp"
    end

    def initialize(config : ConfigHash)
      lp = config["listen_ports"]?
      if (ba = config["bind_address"]?).is_a?(ConfigHash) ||
         !config.has_key?("listen_ports") ||
         !lp.is_a?(String)
        raise InvalidConfigException.new
      end

      @bind_addr = (ba || "0.0.0.0")
      @listen_ports = lp.split(",").map(&.to_u16)
      raise InvalidConfigException.new if @listen_ports.empty?

      buffs_size = EncryptedPacket::MAX_SIZE*2
      @listeners = {} of UInt16 => TCPServer
      @clients = [] of ClientData
      @listen_ports.each do |port|
        @listeners[port] = server = TCPServer.new(@bind_addr, port)
        spawn do
          while client = server.accept?
            puts "Client connected"
            @clients << {
              sock: client, 
              bp: BufferPair.new(buffs_size)
            }
            Fiber.yield
          end
        end
      end
    end

    def close
      @listeners.each do |port, serv|
        serv.close
      end
    end

    def recv_packets(key : Bytes) : Array(Tuple(Packet,UInt64))
      res = [] of Tuple(Packet, UInt64)
      @clients.each_index do |i|
        cd = @clients[i] #client data
        buff = cd[:bp]
        sock = cd[:sock]
        r = buffered_packet_recv(sock, buff, key)
        r.each do |pkt|
          res << {pkt, i.to_u64}
        end
      end
      return res
    end

    def send_packets(pkts : Array(EncryptedPacket), route : UInt64)
      raise ArgumentError.new("Invalid route id #{route}") if @clients.size <= route
      sock = @clients[route][:sock]
      pkts.each do |pkt|
        pkt.to_io(sock)
      end
    end
  end
end
