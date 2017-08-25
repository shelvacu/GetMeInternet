# The purpose of the router is to take in packets to be delivered and decide which transport(s)/route(s) should be used to deliver the packet.

module GetMeInternet
  class Router
    alias TransportInfo = NamedTuple(transport: Transport, last_receive_time: Time)
    @transports = {} of Transport => TransportInfo

    def add_transport(t : Transport)
      @transports[t] = {transport: t, last_receive_time: Time.epoch(0)}
    end

    def packet_from_device(pkt : Packet)
      #TODO
    end
  end
end
