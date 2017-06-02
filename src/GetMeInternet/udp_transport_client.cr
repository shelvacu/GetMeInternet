module GetMeInternet
  class UDPTransportClient
    include TransportClient
    include TransportSinglePacket
    
    def initialize(config : ConfigHash)
      @sock = UDPSocket.new
      @sock.connect(
        config["server_addr"].not_nil!,
        config["port"].to_u16
      )
    end

    delegate close, to: @sock

    def recv_packets(key) : Array(Tuple(Packet,UInt64))
      # TODO: use the same buffer throughout instead of a new one
      # every time
      buff = Bytes.new(65535)
      len, client_addr = @sock.receive(buff)
      
      pkt = EncryptedPacket.from_bytes(buff[0,len])
      return pkt.decrypt(key).map{|v| {v, 0u64}}
    end

    def send_single_packet(pkt, route)
      unless route == 0u64
        raise "Route is not used but was unexpected value #{route}"
      end
      @sock.send pkt.to_bytes
    end

    def connected?
      return true
    end
  end
end
