module GetMeInternet
  module Transport
    abstract def send_packet(pkt : Packet) : Array(Packet)?

    abstract def recv_packets() : Array(Packet)

  end
end
