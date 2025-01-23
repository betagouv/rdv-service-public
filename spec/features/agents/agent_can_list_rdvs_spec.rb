RSpec.describe "Agent can list RDVs" do
  let!(:organisation) { create(:organisation) }
  let!(:current_agent) { create(:agent, organisations: [organisation]) }
  let!(:user) { create(:user) }

  def user_profile_path(user)
    admin_organisation_user_path(organisation_id: organisation.id, id: user.id)
  end

  before do
    login_as(current_agent, scope: :agent)
  end

  describe "RDV visibility within organisation" do
    let!(:agent_from_same_service) { create(:agent, organisations: [organisation], service: current_agent.services.first) }
    let!(:agent_from_other_service) { create(:agent, organisations: [organisation]) }

    before do
      [current_agent, agent_from_same_service, agent_from_other_service].each do |agent|
        create(:rdv, organisation: organisation, agents: [agent], motif: create(:motif, service: agent.services.first))
      end
    end

    it "displays RDVs whose motif are in the same service as current agent" do
      visit admin_organisation_rdvs_url(organisation, current_agent)
      expect(page).to have_content(current_agent.rdvs.last.motif.name)
      expect(page).to have_content(agent_from_same_service.rdvs.last.motif.name)
      expect(page).not_to have_content(agent_from_other_service.rdvs.last.motif.name)
    end
  end

  context "when a RDV user is soft deleted" do
    let(:active_user) { user }
    let!(:deleted_user) { create(:user) }

    before do
      create(:rdv, organisation: organisation, agents: [current_agent], users: [active_user])
      create(:rdv, organisation: organisation, agents: [current_agent], users: [deleted_user])

      deleted_user.soft_delete
    end

    it "displays deleted users without a link to their profile" do
      visit admin_organisation_rdvs_url(organisation, current_agent)

      # Active user has a link to her profile
      expect(page).to have_link(active_user.full_name, href: user_profile_path(active_user))

      # Deleted user has a link to her profile
      expect(page).to have_content("#{deleted_user}Supprimé")
      expect(page.body).not_to include(user_profile_path(deleted_user))
    end
  end

  context "when a RDV is by_phone with no lieu" do
    before do
      create(:rdv, :by_phone, lieu: nil, organisation: organisation, agents: [current_agent], users: [user])
    end

    it "displays RDVs list with no error" do
      visit admin_organisation_rdvs_url(organisation, current_agent)

      expect(page).to have_content("RDV téléphonique")
      expect(page).to have_content(current_agent.first_name)
      expect(page).to have_link(user.full_name, href: user_profile_path(user))
    end
  end

  describe "searching by user" do
    before do
      create(:rdv, organisation: organisation, users: [user])
    end

    it "allows searching by user", js: true do
      visit admin_organisation_rdvs_path(organisation, current_agent)

      find("#select2-user_id-container").click
      within(".select2-search--dropdown") do
        fill_in(class: "select2-search__field", with: "#{user.last_name} #{user.first_name}")
      end
      find("li", text: "#{user.last_name} #{user.first_name}").click

      # This is to make sure we wait for the user to be added before doing the next action
      expect(page).to have_content(user.reverse_full_name)
      raise "lol"
    end
  end
end
