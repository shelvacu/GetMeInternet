class CircleBuff
  @start : UInt64
  @stop  : UInt64
  @buff  : Bytes
  
  def initialize(size : UInt32)
    initialize(Bytes.new(size))
  end

  def initialize(@buff : Bytes)
    @start = 0
    @stop = 0
  end

  def max_size
    @buff.size
  end
  
  def data_size
    if @start <= @stop
      return @stop - @start
    else
      return max_size - (@start - @stop)
    end
  end

  def valid_index(i : UInt32)
    if @start <= @stop
      return (@start + i) < @stop
    else
      return (@start + i) < max_size ||
             ((@start + i) % max_size) < @stop
    end
  end
  
  def [](i : UInt32)
    raise ArgumentError.new("Invalid index #{i}") unless valid_index(i)
    unsafe_index(i)
  end

  def unsafe_index(i : UInt32)
    @buff[(@start + i) % max_size]
  end

  #Big Endian
  def index_to_u32(i : UInt32) : UInt32
    raise ArgumentError.new("Invalid index #{i} for conversion to UInt32") unless valid_index(i) && valid_index(i+3)
    return unsafe_index(i  ).to_u32 << 24 +
           unsafe_index(i+1).to_u32 << 16 +
           unsafe_index(i+2).to_u32 <<  8 +
           unsafe_index(i+3).to_u32
  end
  
  def read_from(io : IO)
    if @start <= @stop
      # we read in the data in two pieces
      len = (max_size - @stop)
      len_read = io.read(@buff[@stop,len])
      if len_read == len
        second_read_length = io.read(@buff[0,@start])
        total_length_read = len_read + second_read_length
      else
        total_length_read = len_read
      end
      @stop += total_length_read
      @stop %= max_size
      return total_length_read
    else
      len_read = io.read @buff[@stop,(@start-@stop)-1]
      @stop += len_read
      return len_read
    end
  end

  def allocate(num_bytes : UInt32)
    raise ArgumentError.new("Not enough space!") unless max_size - data_size > num_bytes
    old_stop = @stop
    if old_stop + num_bytes < max_size
      @stop += num_bytes
      return @buff[current,num_bytes]
    elsif #TODO
end
