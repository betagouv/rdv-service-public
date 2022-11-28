# frozen_string_literal: true

describe "Agent can sync his account to outlook" do
  let!(:organisation) { create(:organisation) }

  before do
    OmniAuth.config.test_mode = true
    OmniAuth.config.add_mock(:microsoft_graph,
                             { "extra" => { "raw_info" => { "user_principal_name" => "example@outlook.com" } },
                               "credentials" => { "token" => "super_token", "refresh_token" => "super_refresh_token" }, })

    allow(Sentry).to receive(:capture_message)
  end

  after do
    OmniAuth.config.mock_auth[:microsoft_graph] = nil
    clear_enqueued_jobs
  end

  context "the outlook email exists in the app" do
    let!(:agent) { create(:agent, email: "example@outlook.com", basic_role_in_organisations: [organisation]) }

    before do
      login_as(agent, scope: :agent)
      visit agents_calendar_sync_outlook_sync_path
      click_link "Vous connecter avec Outlook"
    end

    it "syncs the account" do
      expect(agent.reload.microsoft_graph_token).to eq("super_token")
      expect(agent.reload.refresh_microsoft_graph_token).to eq("super_refresh_token")
      expect(Outlook::MassCreateEventJob).to have_been_enqueued.with(agent)
      expect(page).to have_content("Votre compte Outlook a bien été connecté")
    end
  end

  context "the outlook email does not exists in the app" do
    let!(:agent) { create(:agent, email: "example@youpi.com", basic_role_in_organisations: [organisation]) }

    before do
      login_as(agent, scope: :agent)
      visit agents_calendar_sync_outlook_sync_path
      click_link "Vous connecter avec Outlook"
    end

    it "syncs the account" do
      expect(agent.reload.microsoft_graph_token).to be_nil
      expect(agent.reload.refresh_microsoft_graph_token).to be_nil
      expect(Outlook::MassCreateEventJob).not_to have_been_enqueued.with(agent)
      expect(Sentry).to have_received(:capture_message).with("Microsoft Graph OmniAuth failed for example@outlook.com")
      expect(page).to have_content("Votre compte Outlook n'a pas pu être connecté. Est-il bien utilisé avec le même email que votre compte RDV Solidarités ?")
    end
  end
end
