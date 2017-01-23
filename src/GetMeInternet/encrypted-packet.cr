module GetMeInternet
  class EncryptedPacket
    # Packet format
    # * nonce (Sodium::SecretBox::NONCE_BYTES in size)
    # * data length (UInt32)
    # * data (containing one or more Packets, encrypted)

    def self.encrypt(pkt : Packet)
      encrypt([pkt])
    end
    
    def self.encrypt(pkts : Array(Packet), key : Bytes)
      size = pkts.map(&.bytesize).sum
      plaintext = Bytes.new(size)
      io = IO::Memory.new(plaintext)
      pkts.each do |pkt|
        pkt.to_io(io)
      end
      return self.new Sodium::SecretBox.encrypt(plaintext, key)
    end
    
    def initialize(@ciphertext : Bytes, @nonce : Bytes)
      raise ArgumentError.new unless @nonce.size == NONCE_LENGTH
    end

    def decrypt(key : Bytes) : Array(Packet)
      content = Sodium::SecretBox.decrypt(@ciphertext, @nonce, key)
      res = [] of Packet
      io = IO::Memory.new(content, writable: false)
      while io.pos < io.size
        res << Packet.from_io(io)
      end
      return res
    end
  end
end
