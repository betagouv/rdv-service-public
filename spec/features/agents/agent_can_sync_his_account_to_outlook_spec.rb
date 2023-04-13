# frozen_string_literal: true

describe "Agent can sync his account to outlook" do
  let!(:organisation) { create(:organisation) }
  let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
  let!(:rdv) { create(:rdv, organisation: organisation, agents: [agent], starts_at: 10.days.ago) }

  let(:client_double) { instance_double(Outlook::ApiClient) }

  before do
    allow(Outlook::ApiClient).to receive(:new).with(agent).and_return(client_double)
  end

  before do
    OmniAuth.config.test_mode = true
    OmniAuth.config.add_mock(:microsoft_graph,
                             { "extra" => { "raw_info" => { "user_principal_name" => "example@outlook.com" } },
                               "credentials" => { "token" => "super_token", "refresh_token" => "super_refresh_token" }, })
  end

  after do
    OmniAuth.config.mock_auth[:microsoft_graph] = nil
  end

  it "syncs the account" do
    login_as(agent, scope: :agent)
    visit agents_calendar_sync_outlook_sync_path

    expect(client_double).to receive(:create_event!)
    perform_enqueued_jobs do
      find(:xpath, "//a/img[@alt=\"S'identifier avec Microsoft\"]").find(:xpath, "..").click

      expect(agent.reload.microsoft_graph_token).to eq("super_token")
      expect(agent.reload.refresh_microsoft_graph_token).to eq("super_refresh_token")
      expect(page).to have_content("Votre compte Outlook a bien été connecté")
    end
  end
end
