require "./monotonic"

module GetMeInternet
  #################################################################
  # Purpose: To recieve packets from the virtual tunnel device and
  # send across the appropriate transport(s). Packets should be
  # given to the router un-encrypted, so that in the future the IP
  # header can be read and decisions can be made based on that.
  class Router
    alias TransportInfo = NamedTuple(
            transport: Transport,
            last_packet_received: MonotonicTime
          )

    @transports = {} of Transport => TransportInfo

    
  end
end
