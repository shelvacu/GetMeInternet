module GetMeInternet
  module TransportSinglePacket
    include Transport
    
    def send_packets(pkts : Array(EncryptedPacket),
                     route : UInt64)
      pkts.each do |pkt|
        send_single_packet(pkt, route)
      end
    end

    def send_packet(pkt, route)
      send_single_packet(pkt,route)
    end

    abstract def send_single_packet(pkt : EncryptedPacket, route : UInt64)
  end
end
