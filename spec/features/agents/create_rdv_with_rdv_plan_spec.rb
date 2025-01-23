RSpec.describe "Les agents peuvent prendre un rendez-vous en passant par l'interface de rdv_plan" do
  let!(:organisation) { create(:organisation) }
  let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
  let!(:motif) { create(:motif, service: agent.services.first, organisation: organisation, location_type: :public_office) }
  let!(:lieu) { create(:lieu, organisation: organisation) }

  let!(:user) do
    create(:user, :unregistered, organisations: [organisation]) # créé par appel d'api par l'appli qui s'intègre avec nous
  end
  let(:rdv_plan) do
    create(:rdv_plan, user: user, planning_agent: agent)
  end

  before { login_as(agent, scope: :agent) }

  it "permet de prendre un rendez-vous", js: true do
    visit agents_rdv_plan_path(rdv_plan.id)
    find(".fc-widget-content", match: :first).click
    expect(page).to have_content "Nouveau"
    expect(rdv_plan.reload.starts_at).to be_present
    find("label", text: "Sur place").click
    click_on "Continuer"
    expect(page).to have_content "Motif du rendez-vous "
    click_on "Continuer"

    fill_in("Email", with: "newaddress@exemple.com")

    expect(page).to have_content "Envoyer une notification de confirmation"
    click_on "Confirmer le rendez-vous"

    expect(page).to have_content "Rendez-vous confirmé"
    rdv = Rdv.last
    expect(rdv).to have_attributes(
      users: [user],
      agents: [agent],
      motif: motif,
      lieu: lieu,
      organisation: organisation
    )
    expect(user.reload.email).to eq "newaddress@exemple.com"
  end
end
