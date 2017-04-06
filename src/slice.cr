class Slice(T)

  # Use like:
  # `buff.to_uint(0u64)`
  def to_uint(start : (UInt8 | UInt16 | UInt32 | UIn64)) # Big Endian
    self.reduce(start){|acc, obj| (acc << 8) + obj}
  end
end
