require "./mabf"

module GetMeInternet
  struct Packet
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
    # Header length is therefor 11 bytes

    HEADER_BYTE_LENGTH = 11

    enum PacketType
      Normal
      Ping
      Pong
      Null
      Stream #Not currently used
    end

    def self.from_io(io : IO, dont_care = nil)
      #TODO: always return InvalidPacketException instead of a variety of possible errors
      pt = PacketType.from_value io.read_bytes(UInt8, MABF)
      seq_id = io.read_bytes(UInt64, MABF)
      data_len = io.read_bytes(UInt16, MABF)
      data = Bytes.new(data_len)
      io.read_fully(data)
      self.new(pt, seq_id, data)
    end

    def self.from_bytes(buff : Bytes)
      # TODO: Magic values
      raise "buff not big enough, only #{buff.size} bytes" unless buff.size >= 11
      pt = PacketType.from_value buff[0]
      seq_id = buff[1,8].to_uint(0u64)
      data_len = buff[9,2].to_uint(0u16)
      raise "buff not big enough for data" unless buff.size >= 11+data_len
      data = buff[11,data_len]
      self.new(pt, seq_id, data)
    end
    
    def initialize(@type : PacketType,
                   @seq_id : UInt64,
                   @data : Bytes)
      raise ArgumentError.new("data is too big") if @data.size > 65535
    end

    def ==(other : Packet)
      return type == other.type &&
             seq_id == other.seq_id &&
             data == other.data
    end
    
    def to_io(io : IO, dont_care = nil)
      io.write_bytes(@type.value.to_u8, MABF)
      io.write_bytes(@seq_id, MABF)
      io.write_bytes(@data.size.to_u16, MABF)
      io.write(@data)
    end

    def byte_size
      HEADER_BYTE_LENGTH + @data.size
    end

    def size
      byte_size
    end

    getter :type
    getter :seq_id
    getter :data
  end
end
    
