RSpec.describe "loading seeds" do # rubocop:disable RSpec/DescribeClass
  it "does not crash" do
    Rails.application.load_seed
  end
end
