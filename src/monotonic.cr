module Monotonic
  extend self
  
  def time
    timespec = uninitialized LibC::Timespec
    LibC.clock_gettime(LibC::CLOCK_MONOTONIC, pointerof(timespec))
    return timespec.tv_nsec.to_u64
  end
end
