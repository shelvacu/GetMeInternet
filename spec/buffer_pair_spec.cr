require "spec"

#TODO: Test this better

describe BufferPair do
  it "reads from an io" do
    io = IO::Memory.new("Testola")
    bp = BufferPair.new(500)
    bytes_read = bp.read_from(io)
    bytes_read.should eq 7
    bp.bytes_read.should eq 7
    bp.fullbuff[0,7].should eq Bytes[84, 101, 115, 116, 111, 108, 97]
  end

  it "does stuff" do
    io = IO::Memory.new("Testola")
    bp = BufferPair.new(500)
    bytes_read = bp.read_from(io)
    bp.unused.size.should eq (500-7)

    bp.swap

    bp.bytes_read.should eq 0

    bp.swap

    bp.bytes_read.should eq 0
  end
end
