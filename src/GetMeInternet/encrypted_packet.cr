require "./mabf"

module GetMeInternet
  class EncryptedPacket
    # Packet format
    # * nonce (Sodium::SecretBox::NONCE_BYTES in size)
    # * data length (UInt32)
    # * data (containing one or more Packets, encrypted)

    HEADER_BYTE_LENGTH = NONCE_LENGTH + 4

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
      data_len = io.read_bytes(UInt32, MABF)
      # TODO: DoS attack possibility, limit data_len size
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
      data_len =
        (dem_bytes[NONCE_LENGTH    ].to_u32 << 24) +
        (dem_bytes[NONCE_LENGTH + 1].to_u32 << 16) +
        (dem_bytes[NONCE_LENGTH + 2].to_u32 << 8) +
        (dem_bytes[NONCE_LENGTH + 3].to_u32)

      data = dem_bytes[HEADER_BYTE_LENGTH, data_len]

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
      io = IO::Memory.new(content, writeable: false)
      while io.pos < io.size
        res << Packet.from_io(io)
      end
      return res
    end

    def decrypt_into(key : Bytes, buff : Bytes)
      content = Sodium::SecretBox.decrypt_into(@ciphertext, @nonce, key, buff)
      res = [] of Packet
      pos = 0
      while pos < content.size
        pkt = Packet.from_buffer content+pos
        pos += pkt.size
      end
      return res
    end

    def to_io(io, dont_care = nil)
      io.write(@nonce)
      io.write_bytes(@ciphertext.size.to_u32, MABF)
      io.write(@ciphertext)
    end

    def ==(other : EncryptedPacket)
      return @nonce == other.nonce &&
        @ciphertext == other.ciphertext
    end
  end
end
