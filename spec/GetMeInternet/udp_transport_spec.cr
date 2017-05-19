require "spec"
#require "socket"
#require "../../src/*"
#require "../../src/GetMeInternet/*"

describe GetMeInternet do
  it "Pipes packets over UDP" do
    key = Sodium::SecretBox.secure_random_key
    
    serv = GetMeInternet::UDPTransportServer.new(
      {
        "bind_address" => "127.0.0.1",
        "port" => "7788"
      }
    )

    client = GetMeInternet::UDPTransportClient.new(
      {
        "server_addr" => "127.0.0.1",
        "port" => "7788"
      }
    )

    sleep(1)

    testpkt = GetMeInternet::Packet.new(
      GetMeInternet::Packet::PacketType::Normal,
      2_u64,
      Bytes[1,2,3,4,5]
    )

    enc_testpkt = GetMeInternet::EncryptedPacket.encrypt(testpkt, key)

    client.send_packet(enc_testpkt,0u64)

    #rec_pkts = [] of GetMeInternet::Packet

    sleep(1)
    rec_pkts = serv.recv_packets(key)

    rec_pkts.size.should eq 1

    rec_pkts.first[0].should eq testpkt

    serv.send_packet(enc_testpkt, rec_pkts.first[1])

    rec_pkts = client.recv_packets(key)

    rec_pkts.size.should eq 1

    rec_pkts.first[0].should eq testpkt   
  end
end
