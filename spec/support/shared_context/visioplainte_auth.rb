RSpec.shared_context "Visioplainte Auth" do
  stub_env_with(VISIOPLAINTE_API_KEY: "visioplainte-api-test-key-123456")

  let(:auth_header) do
    { "X-VISIOPLAINTE-API-KEY": "visioplainte-api-test-key-123456" }
  end
end
