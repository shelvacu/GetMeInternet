require "spec"
require "./slice"

describe Slice do
  it "converts Bytes to UInt32 correctly" do
    testcases = [
      {Bytes[0,0,0,0], 0_u32},
      {Bytes[0,0,0,1], 1_u32},
      {Bytes[0,0,1,0], 256_u32},
      {Bytes[0,0,1,1], 257_u32}
    ]
    testcases.each do |inp, outp|
      inp.to_uint(0u32).should eq outp
    end
  end
end
