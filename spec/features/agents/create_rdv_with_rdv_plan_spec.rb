RSpec.describe "Les agents peuvent prendre un rendez-vous en passant par l'interface de rdv_plan" do
  let!(:organisation) { create(:organisation) }
  let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
  let!(:motif) { create(:motif, service: agent.services.first, organisation: organisation, location_type: :public_office) }
  let!(:lieu) { create(:lieu, organisation: organisation) }
  let!(:plage_ouverture) { create(:plage_ouverture, :weekdays, motifs: [motif], lieu: lieu, agent: agent, organisation: organisation) }

  let!(:user) do
    create(:user, organisations: [organisation]) # créé par appel d'api par l'appli qui s'intègre avec nous
  end

  before { login_as(agent, scope: :agent) }

  it "fonctionne depuis un lien avec l'id de l'usager", js: true do
    visit new_agents_rdv_plan_path(user_id: user.id)
    select motif.name
    click_on "Continuer"
    click_on "Prochaine disponibilité"
    save_and_open_screenshot
  end
end
