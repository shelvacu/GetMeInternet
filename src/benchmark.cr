#stupid-simple benchmarking
require "./monotonic"

module Benchmark
  extend self
  
  @[AlwaysInline]
  def benchmark(name : String, &block)
    puts "starting benchmark of #{name}"
    start_time = Monotonic.time
    block.call()
    end_time = Monotonic.time
    puts "#{name} took #{(end_time - start_time)/1000000.0}ms"
  end
end
