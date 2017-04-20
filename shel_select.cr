# Crystal's wrapper around LibC.select is insufficent since it's not possible to know whether a file descriptor was selected because it was ready for reading or ready for writing.

module ShelSelect
  extend self

  def select(read_ios, write_ios, error_ios)
    return self.select(read_ios, write_ios, error_ios, nil).not_nil!
  end
  
  def select(read_ios  : Array(IO::FileDescriptor),
             write_ios : Array(IO::FileDescriptor),
             error_ios : Array(IO::FileDescriptor),
             timeout_sec : Libc::TimeT | Int | Float?)
    if timeout_sec
      sec = LibC::TimeT.new(timeout_sec)
      
      if timeout_sec.is_a? Float
        usec = (timeout_sec - sec) * 10e6
      else
        usec = 0
      end

      timeout = LibC::Timeval.new
      timeout.tv_sec = sec
      timeout.tv_usec = LibC::SusecondsT.new(usec)
      timeout_ptr = pointerof(timeout)
    else
      timeout_ptr = Pointer(LibC::Timeval).null
    end
    max_fd = 0
    {% for name in [read,write,error] %}
      {{name}}_ios.try &.each do |fd|
        max_fd = fd if fd > max_fd
      end
      {{name}}_fdset = FDSet.from_ios({{name}}_ios)
      {{name}}fds_ptr = pointerof({{name}}_fdset).as(LibC::FdSet*)
    {% end %}
    ret = LibC.select(max_fd, readfds_ptr, writefds_ptr, errorfds_ptr, timeout_ptr)
    case ret
    when 0 # Timeout
      nil
    when -1
      raise Errno.new("Error waiting with select()")
    else
      {% for name in [read,write,error] %}
        res_{{name}}_ios = []
        {{name}}_ios.try &.each do |io|
          res_{{name}}_ios << io if {{name}}_fdset.set?(io)
        end
      {% end %}
      return {read:  res_read_ios,
              write: res_write_ios,
              error: res_error_ios}
    end           
  end
end
