RSpec.describe "API authentication with shared secrets for RDV Insertion" do
  let!(:organisation) { create(:organisation) }
  let!(:agent) { create(:agent, password: "Correcth0rse!", admin_role_in_organisations: [organisation]) }
  let!(:absence) { create(:absence, agent: agent) }

  let!(:payload) do
    {
      id: agent.id,
      first_name: agent.first_name,
      last_name: agent.last_name,
      email: agent.email,
    }
  end

  before do
    allow(ENV).to receive(:fetch).with("SHARED_SECRET_FOR_AGENTS_AUTH").and_return("S3cr3T")
  end

  it "log sentry and return error when shared secret is invalid" do
    get(
      api_v1_absences_path,
      headers: {
        uid: agent.email,
        "X-Agent-Auth-Signature": "BAD_PAYLOAD",
      }
    )
    expect(response).to have_http_status(:unauthorized)
    expect(parsed_response_body).to eq({ "errors" => ["Vous devez vous connecter ou vous inscrire pour continuer."] })
    expect(sentry_events.last.message).to eq("API authentication agent was called with an invalid signature !")
  end

  it "log sentry and return error when shared secret is nil" do
    get(
      api_v1_absences_path,
      headers: {
        uid: agent.email,
        "X-Agent-Auth-Signature": nil,
      }
    )
    expect(response).to have_http_status(:unauthorized)
    expect(parsed_response_body).to eq({ "errors" => ["Vous devez vous connecter ou vous inscrire pour continuer."] })
    expect(sentry_events.last.message).to eq("API authentication agent was called with an invalid signature !")
  end

  it "query is correctly processed with the agent authorizations when shared secret is valid" do
    # Pour une raison inconnue, sentry_events n'est pas vide à la fin de ce test
    # donc nous avons recours à ce "expect.to receive".
    expect(Sentry).not_to receive(:capture_message)

    encrypted_payload = OpenSSL::HMAC.hexdigest("SHA256", "S3cr3T", payload.to_json)
    get(
      api_v1_absences_path,
      headers: {
        uid: agent.email,
        "X-Agent-Auth-Signature": encrypted_payload,
      }
    )
    expect(response.status).to eq(200)
    expect(parsed_response_body["absences"].count).to eq(1)
  end
end
