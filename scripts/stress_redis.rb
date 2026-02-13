# Test: Does a large Redis SET block other clients enough to cause timeouts?
#
# Hypothesis: Redis is single-threaded, so writing a ~100MB value blocks all
# other commands until the write is fully received and processed.
# If the write takes longer than REDIS_TIMEOUT (5s), concurrent readers will
# get Redis::CannotConnectError / timeout errors.
#
# Run this in a Rails console connected to production Redis (or a similar setup).

require "benchmark"

LARGE_VALUE_SIZE = 1000 * 1024 * 1024 # 100 MB
REDIS_KEY_BIG = "test:big_file"
REDIS_KEY_SMALL = "test:ping"
NUM_READERS = 5
READ_INTERVAL = 0.1 # seconds between read attempts

# Prepare the large value in memory first (so we only measure Redis time)
large_value = "x" * LARGE_VALUE_SIZE
puts "Prepared #{LARGE_VALUE_SIZE / 1024 / 1024} MB value in memory"

# Pre-set a small key so readers have something to GET
Redis.with_connection { |r| r.set(REDIS_KEY_SMALL, "pong") }

# Track reader results
reader_results = Concurrent::Array.new
stop_readers = Concurrent::AtomicBoolean.new(false)

# Launch reader threads that continuously try to read from Redis
reader_futures = NUM_READERS.times.map do |i|
  Concurrent::Future.execute do
    while !stop_readers.true?
      start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      begin
        Redis.with_connection { |r| r.get(REDIS_KEY_SMALL) }
        elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
        reader_results << { reader: i, elapsed: elapsed.round(4), error: nil }
      rescue => e
        elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
        reader_results << { reader: i, elapsed: elapsed.round(4), error: "#{e.class}: #{e.message}" }
      end
      sleep READ_INTERVAL
    end
  end
end

# Give readers a moment to start
sleep 0.5

# Now write the large value and measure how long it takes
puts "Writing #{LARGE_VALUE_SIZE / 1024 / 1024} MB to Redis..."
write_time = Benchmark.realtime do
  Redis.with_connection { |r| r.set(REDIS_KEY_BIG, large_value) }
end
puts "Write completed in #{write_time.round(3)}s"

# Let readers run a bit more after the write
sleep 1
stop_readers.make_true
reader_futures.each(&:value)

# Cleanup
Redis.with_connection do |r|
  r.del(REDIS_KEY_BIG)
  r.del(REDIS_KEY_SMALL)
end

# Report
puts "\n--- Results ---"
puts "Write time: #{write_time.round(3)}s"

errors = reader_results.select { _1[:error] }
slow_reads = reader_results.select { _1[:elapsed] > 1.0 }
max_read = reader_results.max_by { _1[:elapsed] }

puts "Total read attempts: #{reader_results.size}"
puts "Errors: #{errors.size}"
errors.each { puts "  #{_1}" }
puts "Reads > 1s: #{slow_reads.size}"
slow_reads.each { puts "  reader=#{_1[:reader]} elapsed=#{_1[:elapsed]}s" }
puts "Slowest read: reader=#{max_read[:reader]} elapsed=#{max_read[:elapsed]}s #{max_read[:error]}" if max_read
