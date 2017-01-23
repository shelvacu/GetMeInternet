module GetMeInternet
  class StreamPacket < Packet
    # StreamPacket format (within the "data" part of the packet)
    # * Source Address (UInt32)
    # * Source Port (UInt16)
    # * Dest Address (UInt32
    # * Dest Port (UInt16)
    # * Flags (lol i dunno)
  end
end
