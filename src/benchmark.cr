#stupid-simple benchmarking

module Benchmark
  extend self
  
  @[AlwaysInline]
  def benchmark(name : String, &block)
    puts "starting benchmark of #{name}"
    start_time = Time.new
    block.call()
    end_time = Time.new
    puts "#{name} took #{(end_time - start_time).milliseconds}ms"
  end
end
