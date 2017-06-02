module Monotonic
  extend self
  
  def time
    timespec = uninitialized LibC::Timespec
    LibC.clock_gettime(LibC::CLOCK_MONOTONIC, pointerof(timespec))
    return timespec.tv_nsec.to_u64
  end
end

struct MonotonicTime
  NanosecondsPerMillisecond = 1_000_000
  TimeSpanConversion =
    NanosecondsPerMillisecond / Time::Span::TicksPerMillisecond
  def initialize
    @_inittime_ns = Monotonic.time
  end

  getter _inittime_ns

  def -(other : MonotonicTime)
    span_ns = @_inittime_ns - other.inittime_ns
    return Time::Span.new(span_ns / TimeSpanConversion)
  end

  def till_now
    return MonotonicTime.new() - self
  end
end
