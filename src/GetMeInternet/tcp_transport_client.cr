require "./transport"
require "../buffer_pair"

module GetMeInternet
  class TCPTransportClient
    include TransportClient

    @server_addr : String
    @port : UInt16

    def self.name
      "tcp"
    end

    def initialize(config : ConfigHash)
      @server_addr = config["server_addr"]
      @port = config["port"].to_u16
      @conn = TCPSocket.new(@server_addr, @port)
      @bp = BufferPair.new(EncryptedPacket::MAX_SIZE*2)
    end

    def send_packets(pkts : Array(EncryptedPacket), id : UInt64)
      raise ArgumentError.new unless id == 0u64
      send_packets(pkts)
    end
    
    def send_packets(pkts : Array(EncryptedPacket))
      pkts.each do |pkt|
        pkt.to_io(@conn)
      end
    end

    def recv_packets(key : Bytes) : Array(Tuple(Packet,UInt64))
      return buffered_packet_recv(@conn, @bp, key).map do |pkt|
        {pkt, 0u64}
      end
    end

    delegate close, to: @conn
  end
end
