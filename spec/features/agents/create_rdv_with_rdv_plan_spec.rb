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
    # TODO: faire un cas avec 2 lieux pour ajouter cette étape
    # click_on "Prochaine disponibilité"
    click_on "08:00", match: :first
    click_on "Confirmer le rendez-vous"
    expect(page).to have_content("Le rendez-vous a été créé")

    expect(Rdv.last).to have_attributes(
      users: [user],
      agents: [agent],
      lieu: lieu,
      motif: motif,
      organisation: organisation
    )
  end

  describe "pré-rempli les préférences de notification en fonction du niveau de confidentialité du motif" do
    context "motif non notifié" do
      before do
        motif.update(visibility_type: Motif::VISIBLE_AND_NOT_NOTIFIED)
      end

      let!(:rdv_plan) do
        create(:rdv_plan, starts_at: 5.days.from_now, lieu: lieu, motif: motif, planning_agent: agent, rdv_agent: agent, user: user)
      end

      it "n'envoie pas de notifications" do
        visit edit_user_agents_rdv_plan_path(rdv_plan)
        expect(page).to have_content("Les notifications ne sont pas envoyées pour ce motif de rendez-vous")
        click_on "Confirmer le rendez-vous"
        expect(page).to have_content("Le rendez-vous a été créé")

        expect(Participation.last).to have_attributes(
          user: user,
          send_lifecycle_notifications: false,
          send_reminder_notification: false
        )
      end
    end
  end
end
