# frozen_string_literal: true

describe "Agent can unsync his account to outlook" do
  let!(:organisation) { create(:organisation) }
  let!(:agent) { create(:agent, microsoft_graph_token: "super_token", refresh_microsoft_graph_token: "super_refresh_token", basic_role_in_organisations: [organisation]) }

  before do
    login_as(agent, scope: :agent)
    visit agents_calendar_sync_outlook_sync_path
    click_link "Déconnecter votre compte Outlook"
  end

  it "unsyncs the account" do
    expect(Outlook::MassDestroyEventJob).to have_been_enqueued.with(agent)
    expect(page).to have_content("Votre compte Outlook est bien en cours de déconnexion. Cette action peut prendre plusieurs minutes, nécessaires à la suppression de vos événements dans votre agenda. Rechargez la page un peu plus tard pour voir l'état de la déconnexion.") # rubocop:disable Layout/LineLength
  end
end
