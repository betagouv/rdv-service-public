RSpec.describe "RedirectToRdvInsertionSpec", type: :request do
  before { ENV["RDV_INSERTION_HOST"] = "https://rdv-insertion-host.fr" }

  context "URL is well formed" do
    it "works" do
      get "/i/r/12345"
      expect(response).to redirect_to("https://rdv-insertion-host.fr/r/12345")
    end
  end

  context "URL has spaces before and after" do
    it "does not raise an error" do
      expect { get("/i/r/%2012345%20") }.not_to raise_error
    end

    it "strips the spaces" do
      get "/i/r/%2012345"
      expect(response).to redirect_to("https://rdv-insertion-host.fr/r/12345")
    end
  end

  context "URL has no uuid" do
    it "works" do
      expect { get("/i/r/") }.to raise_error(ActionController::RoutingError)
    end
  end
end
