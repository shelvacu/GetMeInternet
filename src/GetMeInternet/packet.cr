require "./mabf"

module GetMeInternet
  class Packet
    # Packet format: (network endian)
    # * Packet type (1 byte)
    #   * Normal packet, containing an IP packet
    #   * Ping for testing connection and response time and throughput
    #   * Null packet, containing either nothing or jibberish.
    #     Useful for transports like HTTP which require the client
    #     to make a request before data can be set serv -> client.
    #     Also useful for when the server has nothing to send back.
    #   * Stream data
    # * Packet ID - sequential, used to prevent replay attacks. (UInt64)
    # * Data length (UInt16)
    # * Data (lots of bytes)
    #
    # Header length is therefor 13 bytes

    HEADER_BYTE_LENGTH = 13

    enum PacketType
      Normal
      Ping
      Null
      Stream #Not currently used
    end

    def self.from_io(io : IO, fuck_your_stupid_byte_format_I_dont_care = nil)
      #TODO: always return InvalidPacketException instead of a random exception
      pt = PacketType.from_value io.read_bytes(UInt8, MABF)
      seq_id = io.read_bytes(UInt64, MABF)
      data_len = io.read_bytes(UInt16, MABF)
      data = Bytes.new(data_len)
      io.read_fully(data)
      self.new(pt, seq_id, data)
    end
    
    def initialize(@packet_type : PacketType, @seq_id : UInt64, @data : Bytes)
      raise ArgumentError.new("data is too big") if @data.size > 65535
    end

    def ==(other : Packet)
      return packet_type == other.packet_type &&
             seq_id == other.seq_id &&
             data == other.data
    end
    
    def to_io(io : IO, fuck_your_stupid_byte_format_I_dont_care = nil)
      io.write_bytes(@packet_type.value.to_u8, MABF)
      io.write_bytes(@seq_id, MABF)
      io.write_bytes(@data.size.to_u16, MABF)
      io.write(@data)
    end

    def size
      HEADER_BYTE_LENGTH + @data.size
    end

    getter :packet_type
    getter :seq_id
    getter :data
  end
end
    
