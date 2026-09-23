RSpec.describe "Un agent peut choisir le mode de préparation du rdv" do
  let(:rdv_plan) do
    create(:rdv_plan, user:,
                      duration_in_minutes: 30,
                      rdv_agent: agent,
                      planning_agent: agent)
  end
  let!(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }
  let!(:motif) { create(:motif, organisation:, location_type: :phone) }
  let!(:user) { create(:user, organisations: [organisation]) }
  let(:organisation) { create(:organisation) }
  let!(:plage_ouverture) { create(:plage_ouverture, :weekdays, agent:, motifs: [motif], first_day: 2.weeks.ago) }

  before do
    agent.enable_feature!("rdv_invitations")
    login_as(agent, scope: :agent)
  end

  it "permet de passer du choix dans le calendrier à l'envoi d'invitation" do
    visit agents_rdv_plan_path(rdv_plan.id)
    click_on motif.name

    expect(page).to have_content("Nous allons envoyer un email")

    click_on "choisir un horaire directement"

    expect(page).to have_content("cliquez dessus dans l'agenda de l'agent de votre choix")

    click_on "inviter #{user.full_name} à choisir un créneau"

    expect(page).to have_content("Nous allons envoyer un email")

    click_on "Continuer"

    expect(page).to have_content("Un email va être envoyé")
    expect(rdv_plan.reload).to be_by_invitation
  end
end
