module GetMeInternet
  class UDPTransportClient
    include TransportClient
    include TransportSinglePacket
    
    def initialize(config : ConfigHash)
      @sock = UDPSocket.new
      @sock.connect config["server"].not_nil!, config["port"].to_u16
    end

    delegate close, to: @sock

    def recv_packets(key) : Array(Tuple(Packet,UInt64))
      # TODO: use the same buffer throughout instead of a new one
      # every time
      message, client_addr = @sock.receive
      
      pkt = EncryptedPacket.from_bytes(message)
      return [{pkt.decrypt(key), 0u64}]
    end

    def send_single_packet(pkt, route)
      raise "Route is not used but was unexpected value #{route}" unless route != 0u64
      @sock.send pkt.to_bytes
    end
  end
end
