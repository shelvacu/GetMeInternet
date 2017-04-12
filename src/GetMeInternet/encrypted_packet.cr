require "./mabf"

module GetMeInternet
  class EncryptedPacket
    # Packet format
    # * nonce (Sodium::SecretBox::NONCE_BYTES in size)
    # * data length (UInt16)
    # * data (containing one or more Packets, encrypted)

    HEADER_BYTE_LENGTH = NONCE_LENGTH.to_i32 + 2
    MAX_SIZE = HEADER_BYTE_LENGTH + UInt16::MAX

    getter :nonce
    getter :ciphertext
    
    def self.encrypt(pkt : Packet, key : Bytes)
      encrypt([pkt], key)
    end
    
    def self.encrypt(pkts : Array(Packet), key : Bytes)
      size_sum = pkts.map(&.size).sum
      plaintext = Bytes.new(size_sum)
      io = IO::Memory.new(plaintext)
      pkts.each do |pkt|
        pkt.to_io(io)
      end
      return self.new *Sodium::SecretBox.encrypt(plaintext, key)
    end

    def self.from_io(io, dont_care = nil)
      nonce = Bytes.new(NONCE_LENGTH)
      io.read_fully(nonce)
      data_len = io.read_bytes(UInt16, MABF)
      data = Bytes.new(data_len)
      io.read_fully(data)
      return self.new(data, nonce)
    end

    # I was having troubling naming the arguments...
    def self.from_bytes(dem_bytes : Bytes)
      if dem_bytes.size < HEADER_BYTE_LENGTH
        raise "dem_bytes is too small!"
      end

      nonce = dem_bytes[0, NONCE_LENGTH]
      data_len = (dem_bytes + NONCE_LENGTH).to_uint(0u16)
      if dem_bytes.size < (HEADER_BYTE_LENGTH + data_len)
        raise "dem_bytes is too small! expected at least #{HEADER_BYTE_LENGTH + data_len} bytes of length but dem_bytes is only #{dem_bytes.size} bytes long"
      end
      start = HEADER_BYTE_LENGTH
      count = data_len
      bla = dem_bytes.size
      data = dem_bytes[start, count]

      self.new(data, nonce)
    end
    
    def initialize(@ciphertext : Bytes, @nonce : Bytes)
      raise ArgumentError.new("Nonce is not the correct length, size is #{@nonce.size}, expected #{NONCE_LENGTH}") unless @nonce.size == NONCE_LENGTH
    end

    # How big this packet would be when serialized using to_io
    def byte_size
      return HEADER_BYTE_LENGTH + @ciphertext.size
    end

    def decrypt(key : Bytes) : Array(Packet)
      content = Sodium::SecretBox.decrypt(@ciphertext, @nonce, key)
      res = [] of Packet
      pos = 0u16
      while pos < content.size
        pkt = Packet.from_bytes(content + pos)
        pos += pkt.byte_size
        res << pkt
      end
      return res
    end

    def decrypt_into(key : Bytes, buff : Bytes)
      content = Sodium::SecretBox.decrypt_into(@ciphertext, @nonce, key, buff)
      res = [] of Packet
      pos = 0
      while pos < content.size
        pkt = Packet.from_bytes content+pos
        pos += pkt.size
        res << pkt
      end
      return res
    end

    def to_io(io : IO, dont_care = nil)
      io.write(@nonce)
      io.write_bytes(@ciphertext.size.to_u16, MABF)
      io.write(@ciphertext)
    end

    def to_bytes(buff : Bytes)
      @nonce.copy_to(buff)
      buff[NONCE_LENGTH    ] = (@ciphertext.size >> 8).to_u8
      buff[NONCE_LENGTH + 1] = @ciphertext.size.to_u8
      @ciphertext.copy_to(buff + HEADER_BYTE_LENGTH)
    end

    def ==(other : EncryptedPacket)
      return @nonce == other.nonce &&
        @ciphertext == other.ciphertext
    end
  end
end
