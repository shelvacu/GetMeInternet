require "./transport"
require "../address"

module GetMeInternet
  class UDPTransportServer
    include TransportServer
    include TransportSinglePacket

    def initialize(config : ConfigHash)
      @sock = UDPSocket.new
      @sock.bind "0.0.0.0", config["port"].to_u16
    end

    delegate close, to: @sock

    def recv_packets(key) : Array(Tuple(Packet,UInt64))
      # TODO: use the same buffer throughout instead of a new one
      # every time
      buff = Bytes.new(65535)
      len, client_addr = @sock.receive(buff)

      # this client_addr to route translation should be factored out at least into separate functions
      route = client_addr.address_as_u32.to_u64 + (client_addr.port.to_u64 << 32)
      
      pkt = EncryptedPacket.from_bytes(buff[0,len])
      return pkt.decrypt(key).map{|v| {v, route}}
    end

    def send_single_packet(pkt : EncryptedPacket,
                           route : UInt64)
      port = (route >> 32).to_u16

      raise "route (#{route}) is invalid (calculated port or addr is 0)" if route.to_u32 == 0 || port == 0
      
      @sock.send(pkt.to_bytes, Socket::IPAddress.new(route.to_u32, port))
    end
  end
end
