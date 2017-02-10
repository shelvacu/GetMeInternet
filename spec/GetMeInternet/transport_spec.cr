require "spec"

describe GetMeInternet::Transport do
  it "converts Bytes to UInt32 correctly" do
    testcases = [
      {[0u8,0u8], 0_u32},
      {[0u8,1u8], 1_u32},
      {[1u8,0u8], 256_u32},
      {[1u8,1u8], 257_u32}
    ]
    testcases.each do |inp, outp|
      GetMeInternet::Transport.bytes_to_u32(inp).should eq outp
    end
  end
end
