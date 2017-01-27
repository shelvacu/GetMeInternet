module GetMeInternet
  alias ConfigHash = Hash(String, (ConfigHash | String))

  module Transport
    class InvalidConfigError < Exception
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
    abstract def recv_packets : Array(Tuple(EncryptedPacket,Int))

    # If the transport needs to do something every tick (eg TCP
    # accepting new clients) do it here.
    #def tick
    #end
  end

  module TransportClient
    include Transport

    # Send some packets along the transport. May return some recieved
    # packets, such as with the HTTP transport.
    abstract def send_packets(pkts : Array(EncryptedPacket)
                             ) : Array(Packet)?

    # This is used when something needs to be sent to get packets
    # back. For example, the HTTP transport. All other transports
    # simply return nil.
    def ask_for_more
      return nil
    end
  end

  module TransportServer
    include Transport

    abstract def send_packets(pkts : Array(EncryptedPacket),
                              route : Int)
  end
end
