class BufferPair
  def initialize(size)
    @buff_a = Bytes.new(size)
    @buff_b = Bytes.new(size)
    @use_a = true
    @bytes_read_a = 0u64
    @bytes_read_b = 0u64
  end

  def bytes_read
    if @use_a
      @bytes_read_a
    else
      @bytes_read_b
    end
  end

  def otherbytesreadsetto(val)
    if @use_a
      @bytes_read_b = val
    else
      @bytes_read_a = val
    end
  end

  def bytesreadsetto(val)
    if @use_a
      @bytes_read_a = val
    else
      @bytes_read_b = val
    end
  end

  def fullbuff
    if @use_a
      @buff_a
    else
      @buff_b
    end
  end

  def otherbuff
    if @use_a
      @buff_b
    else
      @buff_a
    end
  end

  def unused
    fullbuff + bytes_read
  end

  def read_from(io : IO, limit = nil)
    if limit.nil?
      len_read = io.read(unused)
    else
      len_read = io.read(unused[0, limit])
    end
    bytesreadsetto(bytes_read + len_read)
    return len_read
  end

  def swap
    bytesreadsetto 0u64
    @use_a = !@use_a
  end
end
