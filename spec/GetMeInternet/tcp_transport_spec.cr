require "spec"

describe GetMeInternet do
  it "Pipes packets over TCP" do
    key = Sodium::SecretBox.secure_random_key
    
    serv = GetMeInternet::TCPTransportServer.new(
      {
        "bind_address" => "127.0.0.1",
        "listen_ports" => "7788"
      }
    )

    client = GetMeInternet::TCPTransportClient.new(
      {
        "server_addr" => "127.0.0.1",
        "port" => "7788"
      }
    )

    #sleep(1)

    testpkt = GetMeInternet::Packet.new(
      GetMeInternet::Packet::PacketType::Normal,
      2_u64,
      Bytes[1,2,3,4,5]
    )

    enc_testpkt = GetMeInternet::EncryptedPacket.encrypt(testpkt, key)

    client.send_packets([enc_testpkt])

    rec_enc_pkts = serv.recv_packets

    rec_enc_pkts.size.should eq 1

    rec_enc_pkts.first[0].decrypt(key).first.should eq testpkt
  end
end
