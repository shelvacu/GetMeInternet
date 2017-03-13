require "./transport"

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
      @buff = Bytes.new(1_000_000) # 2 hard things...
      @bytebuff = [] of UInt8
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

    def recv_packets
      res, @bytebuff = buffered_packet_recv(@conn, @bytebuff, @buff, 0u64)
      return res
    end
  end
end
