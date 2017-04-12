describe GetMeInternet::EncryptedPacket do
  it "survives transport" do
    enc_pkt = GetMeInternet::EncryptedPacket.new(
      Bytes[1,2,3,7,3,5,2],
      Sodium::SecretBox.secure_random_nonce
    )
    io = IO::Memory.new
    enc_pkt.to_io(io)
    io.rewind
    GetMeInternet::EncryptedPacket.from_io(io).should eq enc_pkt
  end

  it "survives serialization to and from buffer" do
    enc_pkt = GetMeInternet::EncryptedPacket.new(
      Bytes[1,2,3,7,3,5,2],
      Sodium::SecretBox.secure_random_nonce
    )
    buff = Bytes.new(enc_pkt.byte_size)
    enc_pkt.to_bytes(buff)
    GetMeInternet::EncryptedPacket.from_bytes(buff).should eq enc_pkt
  end

  it "encrypts and decrypts multiple packets" do
    arr = [
      GetMeInternet::Packet.new(
        GetMeInternet::Packet::PacketType::Ping,
        12345u64,
        Bytes[72, 101, 108, 108, 111]
      ),
      GetMeInternet::Packet.new(
        GetMeInternet::Packet::PacketType::Normal,
        54321u64,
        Bytes[72, 101, 108, 108, 111]
      )
    ]
    key = Sodium::SecretBox.secure_random_key
    enc_pkt = GetMeInternet::EncryptedPacket.encrypt(arr, key)
    enc_pkt.decrypt(key).should eq arr
  end

  it "makes a packet from bytes" do
    GetMeInternet::EncryptedPacket.from_bytes(
      Bytes[
        0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, #The most secure nonce ever /s
        0, 1, # Data length (1)
        0xff # The data
      ]
    ).should eq GetMeInternet::EncryptedPacket.new(
                  Bytes[0xff],
                  Bytes[
                    0, 0, 0, 0, 0, 0, 0, 0,
                    0, 0, 0, 0, 0, 0, 0, 0,
                    0, 0, 0, 0, 0, 0, 0, 0
                  ]
                )
  end
end
