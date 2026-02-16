RSpec.describe "loading seeds" do # rubocop:disable RSpec/DescribeClass
  stub_env_with(DB_SEEDS_USERS_AND_AGENTS_PASSWORD: "Rdvservicepublictest1!")

  it "does not crash" do
    Rails.application.load_seed
  end
end
