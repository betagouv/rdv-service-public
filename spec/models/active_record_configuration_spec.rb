RSpec.describe "ActiveRecord configuration" do # rubocop:disable RSpec/DescribeClass
  it "has enough connections" do
    # voir https://guides.rubyonrails.org/configuring.html#config-active-record-global-executor-concurrency
    pool_size = ActiveRecord::Base.connection.pool.stat[:size]
    expect(pool_size).to eq(ENV.fetch("RAILS_MAX_THREADS", 5) + Rails.configuration.active_record.global_executor_concurrency)
  end
end
