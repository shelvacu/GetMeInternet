require "spec"

describe GetMeInternet::Packet do
  it "slurps from an IO" do
    pkt_data = Bytes[
      0x00, #type (Normal)
      0xde,0xad,0xbe,0xef,0xde,0xad,0xbe,0xef, #Packet ID (DEADBEEFDEADBEEF)
      0, 5, # Data length (5)
      72, 101, 108, 108, 111 # Data ("Hello")
    ]
    io = IO::Memory.new(pkt_data, writeable: false)
    pkt = GetMeInternet::Packet.from_io(io)
    pkt.size.should eq pkt_data.size
    pkt.type.should eq GetMeInternet::Packet::PacketType::Normal
    pkt.seq_id.should eq 0xDEADBEEFDEADBEEF_u64
    pkt.data.should eq Bytes[72, 101, 108, 108, 111]
  end

  it "writes to an IO" do
    pkt = GetMeInternet::Packet.new(
      GetMeInternet::Packet::PacketType::Ping,
      12345u64,
      Bytes[72, 101, 108, 108, 111]
    )
    outb = Bytes.new pkt.size
    pkt.to_io(IO::Memory.new(outb))
    expected = Bytes[
      0x01,
      0,0,0,0,0,0,48,57,
      0, 5,
      72, 101, 108, 108, 111
    ]
    outb.should eq expected
  end

  it "survives transport" do
    pkt_a = GetMeInternet::Packet.new(
      GetMeInternet::Packet::PacketType::Ping,
      12345u64,
      Bytes[72, 101, 108, 108, 111]
    )
    io = IO::Memory.new
    pkt_a.to_io(io)
    io.rewind
    pkt_b = GetMeInternet::Packet.from_io(io)
    pkt_a.should eq pkt_b
  end

  it "doesn't care about your stupid byte format" do
    pkt_a = GetMeInternet::Packet.new(
      GetMeInternet::Packet::PacketType::Ping,
      12345u64,
      Bytes[72, 101, 108, 108, 111]
    )
    io = IO::Memory.new
    pkt_a.to_io(io, "flargedyBOOP")
    io.rewind
    pkt_b = GetMeInternet::Packet.from_io(io, IO::ByteFormat::LittleEndian)
    pkt_a.should eq pkt_b
  end
end
