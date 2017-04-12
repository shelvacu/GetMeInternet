struct Slice(T)
  # Use like:
  # `buff.to_uint(0u64)`

  {% for tipe, size in {UInt8 => 1, UInt16 => 2, UInt32 => 4, UInt64 => 8} %}
    def to_uint(start : {{tipe}}) : {{tipe}}
      self[0,{{size}}].reduce(start){|acc, obj| (acc << 8) + obj}
    end
  {% end %}
  
  #def to_uint(start : (UInt8 | UInt16 | UInt32 | UInt64)) # Big Endian
  #  size = case start.class
  #         when UInt8
  #           1
  #         when UInt16
  #           2
  #         when UInt32
  #           4
  #         when UInt64
  #           8
  #         end
  #  self[0,size].reduce(start){|acc, obj| (acc << 8) + obj}
  #end
end
