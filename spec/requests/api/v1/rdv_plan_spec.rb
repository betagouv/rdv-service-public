RSpec.describe "RDV Plan API" do
  describe "#create" do
    context "when the user doesn't already exist" do
      post "/api/v1/rdv_plans"
    end
  end
end
