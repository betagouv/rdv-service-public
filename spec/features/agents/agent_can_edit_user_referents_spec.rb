# frozen_string_literal: true

RSpec.describe "Agent can edit a user's referents" do
  let!(:current_org) { create(:organisation) }
  let!(:another_org_i_admin) { create(:organisation) }
  let!(:current_agent) { create(:agent, admin_role_in_organisations: [current_org, another_org_i_admin]) }

  let!(:referent_in_current_org) { create(:agent, last_name: "DANSLORG", basic_role_in_organisations: [current_org]) }
  let!(:referent_in_org_i_admin) { create(:agent, last_name: "DANSUNEDEMESORGS", basic_role_in_organisations: [another_org_i_admin]) }
  let!(:referent_in_other_org) { create(:agent, last_name: "AILLEURS", basic_role_in_organisations: [create(:organisation)]) }

  let!(:user) { create(:user, referent_agents: [referent_in_current_org, referent_in_org_i_admin, referent_in_other_org], organisations: [current_org]) }

  before { login_as(current_agent, scope: :agent) }

  it "allows listing current referents, removing them and adding new ones" do
    visit admin_organisation_user_path(current_org.id, user.id)
    expect(page).to have_content("DANSLORG")
    expect(page).to have_content("DANSUNEDEMESORGS")
    expect(page).not_to have_content("AILLEURS")

    # On clique sur "Modifier" pour éditer les référents
    find("a[href='#{admin_organisation_user_referent_assignations_path(current_org.id, user.id)}']").click
    # On retrouve les mêmes référents que sur le profil usager
    expect(page).to have_content("DANSLORG")
    expect(page).to have_content("DANSUNEDEMESORGS")
    expect(page).not_to have_content("AILLEURS")

    # On peut retirer un référent, même si il est dans une autre org
    within("#agent_#{referent_in_org_i_admin.id}") do
      expect { click_on "Retirer" }.to change { user.referent_assignations.count }.from(3).to(2)
    end

    # On peut ajouter un référent (ici je m 'ajoute moi-même)
    within("#agent_#{current_agent.id}") do
      expect { click_on "Ajouter" }.to change { user.referent_assignations.count }.from(2).to(3)
    end
  end
end
