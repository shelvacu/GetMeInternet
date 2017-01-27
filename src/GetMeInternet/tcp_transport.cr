require "./transport"

module GetMeInternet
  module TCPTransportServer
    include TransportServer

    ClientData = NamedTuple(sock: TCPSocket, buff: Array(UInt8))

    def self.name
      return "tcp"
    end
    
    def initialize(config : ConfigHash)
      if (ba = config["bind_address"]?).is_a?(ConfigHash) ||
         !config.has_key?("listen_ports") ||
         (lp = config["listen_ports"]).is_a?(ConfigHash)
        raise InvalidConfigException
      end

      @bind_addr = (ba || "0.0.0.0")
      @listen_ports = lp.split(",").map(&.to_u32)
      raise InvalidConfigException if @listen_ports.empty?

      @listeners = {} of UInt32 => TCPServer
      @clients = [] of ClientData
      @listen_ports.each do |port|
        @listeners[port] = server = TCPServer.new(@bind_addr, port)
	spawn do
	  while client = server.accept?
	    client.blocking = false
	    @clients << {sock: client, buff: [] of UInt8}
	  end
	end
      end
    end

    def recv_packets
      res = [] of EncryptedPacket
      megabuff = Bytes.new(1_000_000)
      @clients.each_index do |i|
        cd = @clients[i] #client data
        buff = cd[:buff]
	sock = cd[:sock]
        len_read = sock.read(megabuff)
        
        # pre-expand array?
        megabuff[0,len_read].each do |byte|
          buff << byte
        end
        if buff.size >= EncryptedPacket::HEADER_BYTE_LENGTH
          pkt_len = EncryptedPacket::HEADER_BYTE_LENGTH
          # TODO: no magic value
          length_range = (NONCE_LENGTH..NONCE_LENGTH+4)
          pkt_len += buff[length_range].reduce(0u32) do |acc, val|
            (acc << 8) + val
          end
          if buff.size >= pkt_len
            # This *really* feels like it should really be optimized,
            # but premature optimization is the root of all evil.
            io = IO::Memory.new
            buff[0..pkt_len].each do |byte|
              io.write_byte byte
            end
            io.rewind

            res << {EncryptedPacket.from_io(io), i}
            #TODO: Catch invalid packet exceptions

            @clients[i] = {sock: sock, buff: buff[pkt_len..-1]}
          end
        end
      end
      return res
    end

    def send_packets(pkts : Array(EncryptedPacket), route : Int)
      raise ArgumentError.new if @clients.length <= route
      sock = @clients[route][:sock]
      pkts.each do |pkt|
        pkt.to_io(sock)
      end
    end
  end
end
