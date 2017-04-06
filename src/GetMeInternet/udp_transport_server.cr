require "./transport"
require "../address"

module GetMeInternet
  class UDPTransportServer
    include TransportServer

    def initialize(config : ConfigHash)
      @sock = UDPSocket.new
      @sock.bind "0.0.0.0", config["port"].to_u16
    end

    delegate close, to: @sock

    def recv_packets
      # TODO: use the same buffer throughout instead of a new one
      # every time
      message, client_addr = @sock.receive
      
      pkt = EncryptedPacket.from_bytes(message)
      return [{pkt, client_addr.address_as_u32.to_u64}]
    end

    def send_packets(pkts : Array(EncryptedPacket),
                     route : UInt64)
      pkts.each do |pkt|
        send_packet(pkt, route)
      end
    end

    def send_packet(pkt : EncryptedPacket,
                    route : UInt64)
      @sock.send #unfinished... in case you can't tell
  end
end
