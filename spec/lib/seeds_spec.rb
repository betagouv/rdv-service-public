RSpec.describe "loading seeds" do
  it "does not crash" do
    Rails.application.load_seed
  end
end
