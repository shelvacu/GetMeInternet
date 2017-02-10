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

    # Receive some packets. May return an empty array.
    # The second element in the tuple is the 'route', which in the
    # case of TCP is which client to send to  
    abstract def recv_packets : Array(Tuple(EncryptedPacket,UInt64))

    # If the transport needs to do something every tick (eg TCP
    # accepting new clients) do it here.
    def tick
      return nil
    end
    
    # Send some packets along the transport.
    abstract def send_packets(pkts : Array(EncryptedPacket),
                              route : UInt64)

    # recieve packets, using a buffer to deal with only recieving
    # parts of a packet at a time.
    protected def buffered_packet_recv(
                    io : IO,
                    buff : Array(UInt8),
                    bigbuff : Bytes,
                    route_id : UInt64
                  )
      res = [] of Tuple(EncryptedPacket, UInt64)
      len_read = io.read(bigbuff)

      newbuff = buff
      
      bigbuff[0,len_read].each do |byte|
        buff << byte
      end
      if buff.size >= EncryptedPacket::HEADER_BYTE_LENGTH
          pkt_len = EncryptedPacket::HEADER_BYTE_LENGTH
          # TODO: no magic value
          length_range = (NONCE_LENGTH...NONCE_LENGTH+4)
          pkt_len += Transport.bytes_to_u32(buff[length_range])
          if buff.size >= pkt_len
            # This *really* feels like it should really be optimized,
            # but premature optimization is the root of all evil.
            io = IO::Memory.new
            buff[0..pkt_len].each do |byte|
              io.write_byte byte
            end
            io.rewind

            res << {EncryptedPacket.from_io(io), route_id}
            #TODO: Catch invalid packet exceptions

            newbuff = buff[pkt_len..-1]
          end
        end
      return res, newbuff
    end

    def self.bytes_to_u32(data : Array(UInt8))
      data.reduce(0_u32) do |acc, val|
        (acc << 8) + val
      end
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
