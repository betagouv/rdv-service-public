RSpec.describe Redis do
  describe "#with_connection" do
    it "is fast because it is pooled" do
      starting_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      10000.times do
        described_class.with_connection do |redis|
          redis.set("key", "value")
        end
      end

      ending_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      elapsed_time = ending_time - starting_time

      # Without using a connection pool, 10000 connection checkouts + SET takes about 3000ms.
      # With a connection pool, 10000 connection checkouts + SET takes about 400ms.
      # This test ensures that 10000 checkouts + SET stays under 1000ms
      expect(elapsed_time).to be < 1.0
    end
  end
end
