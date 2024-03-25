RSpec.describe Redis do
  describe "#with_connection" do
    it "is fast because it is pooled" do
      starting_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      1000.times do
        described_class.with_connection do |redis|
          redis.set("key", "value")
        end
      end

      ending_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      elapsed_time = ending_time - starting_time

      # Without using a connection pool, 1000 connection checkouts + SET takes about 300ms.
      # With a connection pool, 1000 connection checkouts + SET takes about 45ms.
      # This test ensures that 1000 checkouts + SET stays under 100ms
      expect(elapsed_time).to be < 0.1
    end
  end
end
