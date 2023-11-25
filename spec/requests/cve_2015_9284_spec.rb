# Make sure that https://nvd.nist.gov/vuln/detail/CVE-2015-9284 is mitigated
RSpec.describe "CVE-2015-9284", type: :request do
  describe "GET /auth/:provider" do
    it do
      expect { get "/omniauth/github" }.to raise_error(ActionController::RoutingError)
    end
  end

  describe "POST /auth/:provider without CSRF token" do
    let!(:allow_forgery_protection) { ActionController::Base.allow_forgery_protection }

    before { ActionController::Base.allow_forgery_protection = true }

    after { ActionController::Base.allow_forgery_protection = allow_forgery_protection }

    it do
      expect do
        post super_admins_agents_path
      end.to raise_error(ActionController::InvalidAuthenticityToken)
    end
  end
end
