# Test: Does a large Redis SET/GET block other clients enough to cause timeouts?
#
# Hypothesis: Redis is single-threaded, so writing/reading a ~100MB value blocks all
# other commands until the operation is fully processed.
#
# We use a short timeout (0.1s) for readers to detect even brief blocking,
# and a long timeout (5s) for the large operations themselves.
#
# Run this with: rails runner scripts/stress_redis.rb

require "benchmark"

LARGE_VALUE_SIZE = 100 * 1024 * 1024 # 100 MB
REDIS_KEY_BIG = "test:big_file"
REDIS_KEY_SMALL = "test:ping"
NUM_READERS = 5
READ_INTERVAL = 0.1 # seconds between read attempts

REDIS_URL = Rails.configuration.x.redis_url
READER_TIMEOUT = 0.1   # short timeout to detect blocking
WRITER_TIMEOUT = 30     # long timeout for large operations

def new_redis(timeout:)
  Redis.new(url: REDIS_URL, timeout: timeout, ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE })
end

# Prepare the large value in memory first (so we only measure Redis time)
large_value = "x" * LARGE_VALUE_SIZE
puts "Prepared #{LARGE_VALUE_SIZE / 1024 / 1024} MB value in memory"

# Pre-set a small key so readers have something to GET
new_redis(timeout: WRITER_TIMEOUT).set(REDIS_KEY_SMALL, "pong")

# Track reader results
reader_results = Concurrent::Array.new
stop_readers = Concurrent::AtomicBoolean.new(false)

# Launch reader threads that continuously try to read from Redis with a short timeout
reader_futures = NUM_READERS.times.map do |i|
  Concurrent::Future.execute do
    reader = new_redis(timeout: READER_TIMEOUT)
    while !stop_readers.true?
      start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      begin
        reader.get(REDIS_KEY_SMALL)
        elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
        reader_results << { reader: i, elapsed: elapsed.round(4), error: nil }
      rescue => e
        elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
        reader_results << { reader: i, elapsed: elapsed.round(4), error: "#{e.class}: #{e.message}" }
      end
      sleep READ_INTERVAL
    end
    reader.close
  end
end

# Give readers a moment to start
sleep 0.5

# Now write the large value and measure how long it takes
puts "Writing #{LARGE_VALUE_SIZE / 1024 / 1024} MB to Redis..."
writer = new_redis(timeout: WRITER_TIMEOUT)
write_time = Benchmark.realtime do
  writer.set(REDIS_KEY_BIG, large_value)
end
puts "Write completed in #{write_time.round(3)}s"

# Let readers run a bit more after the write
sleep 1
stop_readers.make_true
reader_futures.each(&:value)

def report(label, results, duration)
  errors = results.select { _1[:error] }
  slow_reads = results.select { _1[:elapsed] > READER_TIMEOUT }
  max_read = results.max_by { _1[:elapsed] }

  puts "\n--- #{label} ---"
  puts "Duration: #{duration.round(3)}s"
  puts "Total read attempts: #{results.size}"
  puts "Errors: #{errors.size}"
  errors.each { puts "  #{_1}" }
  puts "Reads > #{READER_TIMEOUT}s: #{slow_reads.size}"
  slow_reads.each { puts "  reader=#{_1[:reader]} elapsed=#{_1[:elapsed]}s" }
  puts "Slowest read: reader=#{max_read[:reader]} elapsed=#{max_read[:elapsed]}s #{max_read[:error]}" if max_read
end

write_reader_results = reader_results
report("Phase 1: SET #{LARGE_VALUE_SIZE / 1024 / 1024} MB", write_reader_results, write_time)

# --- Phase 2: GET the large value while readers are active ---
read_reader_results = Concurrent::Array.new
stop_readers = Concurrent::AtomicBoolean.new(false)

reader_futures = NUM_READERS.times.map do |i|
  Concurrent::Future.execute do
    reader = new_redis(timeout: READER_TIMEOUT)
    while !stop_readers.true?
      start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      begin
        reader.get(REDIS_KEY_SMALL)
        elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
        read_reader_results << { reader: i, elapsed: elapsed.round(4), error: nil }
      rescue => e
        elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
        read_reader_results << { reader: i, elapsed: elapsed.round(4), error: "#{e.class}: #{e.message}" }
      end
      sleep READ_INTERVAL
    end
    reader.close
  end
end

sleep 0.5

puts "\nReading #{LARGE_VALUE_SIZE / 1024 / 1024} MB from Redis..."
reader_big = new_redis(timeout: WRITER_TIMEOUT)
read_time = Benchmark.realtime do
  reader_big.get(REDIS_KEY_BIG)
end
puts "Read completed in #{read_time.round(3)}s"

sleep 1
stop_readers.make_true
reader_futures.each(&:value)

report("Phase 2: GET #{LARGE_VALUE_SIZE / 1024 / 1024} MB", read_reader_results, read_time)

# Cleanup
cleanup = new_redis(timeout: WRITER_TIMEOUT)
cleanup.del(REDIS_KEY_BIG)
cleanup.del(REDIS_KEY_SMALL)
cleanup.close
writer.close
reader_big.close
