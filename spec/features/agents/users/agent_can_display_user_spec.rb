# frozen_string_literal: true

describe "Agent can display user" do
  let!(:organisation) { create(:organisation) }
  let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }

  before do
    login_as(agent, scope: :agent)
    visit admin_organisation_user_path(organisation, user)
  end

  context "when user is unregistered and never logged through FranceConnect" do
    let!(:user) { create(:user, :unconfirmed, :unregistered, organisations: [organisation]) }

    it "prompts the agent to invite the user" do
      expect(page).to have_content("Cet usager ne s'est pas encore créé de compte RDV Solidarités.")
      expect(page).to have_link("Inviter", href: invite_admin_organisation_user_path(id: user.id, organisation_id: organisation.id))
    end
  end

  context "when user is unregistered but has logged through FranceConnect" do
    let!(:user) { create(:user, :unconfirmed, :unregistered, logged_once_with_franceconnect: true, organisations: [organisation]) }

    it "displays a message to inform of FranceConnect binding, and hides the invitation prompt" do
      expect(page).to have_content("Cet usager s'est déjà connecté via FranceConnect.")
      # There is no need to invite the user since FranceConnect binding is in place
      expect(page).not_to have_content("Cet usager ne s'est pas encore créé de compte")
    end
  end
end
