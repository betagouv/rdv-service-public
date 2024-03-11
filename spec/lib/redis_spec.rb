RSpec.describe "Redis connection" do
  it "timeouts at 5 seconds" do
    allow(Redis).to receive(:new).and_wrap_original do |original_method, args, &block|
      new_settings = args.except(:connect_timeout, :read_timeout, :write_timeout).merge(timeout: 0.00000000001)
      original_method.call(new_settings, &block)
    end

    expect do
      Redis.with_connection do |redis|
        redis.get("key")
      end
    end.to raise_error(Redis::TimeoutError)
  end
end
