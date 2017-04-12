require "../slice"
module GetMeInternet
  alias ConfigHash = Hash(String, (ConfigHash | String))

  module Transport
    class InvalidConfigException < Exception
    end

    # A name for the transport, to determine which part of the config
    # to pull configuration for this transport from. Lowercase,
    # underscore-separated. Should be the same for both server and
    # client.
    #
    # EG: "tcp", "http", "ping", "some_other_method"
    # Abstract defs aren't allowed on a meta-class, so you're on the
    # honor system to include this in any including class.
    #abstract def self.name : String

    # Transports must verify config hash and raise an instance of
    # InvalidConfigException if invalid.
    #
    # Any setup (such as setting up listeners or establishing a
    # connection) should be done here.
    abstract def initialize(config : ConfigHash)

    # Tear down the connection and/or server
    abstract def close()

    # Receive some packets. May return an empty array.
    # The second element in the tuple is the 'route', which (in the
    # case of TCP) is which client to send to
    abstract def recv_packets(key : Bytes) : Array(Tuple(Packet,UInt64))

    # Send some packets along the transport.
    abstract def send_packets(pkts : Array(EncryptedPacket),
                              route : UInt64)

    def send_packet(pkt : EncryptedPacket, route : UInt64)
      send_packets([pkt], route)
    end

    # Note: Any returned packets must be dealt with and unused
    # by the time buffered_packet_recv is next called
    protected def buffered_packet_recv(
                    io : IO,
                    bp : BufferPair,
                    key : Bytes
                  ) : Array(GetMeInternet::Packet)
      # TODO: limit to max size of one enc packet
      bp.read_from(io, limit: nil)
      if bp.bytes_read >= EncryptedPacket::HEADER_BYTE_LENGTH
        pkt_len = EncryptedPacket::HEADER_BYTE_LENGTH
        pkt_data_size = (bp.fullbuff + NONCE_LENGTH).to_uint(0u16)
        pkt_len += pkt_data_size
        if bp.bytes_read >= pkt_len
          epkt = EncryptedPacket.from_bytes(bp.fullbuff)
          leftover = bp.bytes_read - epkt.byte_size
          bp.fullbuff[epkt.byte_size, leftover].copy_to bp.otherbuff
          bp.otherbytesreadsetto(leftover)
          
          pkts = epkt.decrypt_into(key, bp.fullbuff + epkt.byte_size)

          # reset & swap buffers
          bp.swap
          return pkts
        end
      end
      return [] of GetMeInternet::Packet
    end
  end

  module TransportClient
    include Transport
    # This is used when something needs to be sent to get packets
    # back. For example, the HTTP transport. All other transports
    # simply return nil.
    def ask_for_more
      return nil
    end
  end

  module TransportServer
    include Transport
  end
end
