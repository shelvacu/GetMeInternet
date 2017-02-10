require "./transport"

module GetMeInternet
  class TCPTransportServer
    include TransportServer

    @bind_addr : String
    @listen_ports : Array(UInt16)
    
    alias ClientData = NamedTuple(sock: TCPSocket, buff: Array(UInt8))

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

      @listeners = {} of UInt16 => TCPServer
      @clients = [] of ClientData
      @listen_ports.each do |port|
        @listeners[port] = server = TCPServer.new(@bind_addr, port)
	spawn do
	  while client = server.accept?
	    client.blocking = false
	    @clients << {sock: client, buff: [] of UInt8}
            Fiber.yield
	  end
	end
      end
      @megabuff = Bytes.new(1_000_000)
    end

    def recv_packets
      res = [] of Tuple(EncryptedPacket, UInt64)
      @clients.each_index do |i|
        cd = @clients[i] #client data
        buff = cd[:buff]
	sock = cd[:sock]
        r, newbuff = buffered_packet_recv(sock, buff, @megabuff, i.to_u64)
        res += r
        @clients[i] = {sock: sock, buff: newbuff}
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
