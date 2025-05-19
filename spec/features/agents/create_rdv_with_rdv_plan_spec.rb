RSpec.describe "Les agents peuvent prendre un rendez-vous en passant par l'interface de rdv_plan" do
  let!(:organisation) { create(:organisation) }
  let(:application) do
    create(:oauth_application,
           name: "Démarches Simplifiées",
           redirect_uri: "http://localhost:4567/omniauth/rdvservicepublic/callback\nhttp://demo.demarches-simplifiees.fr/omniauth/rdvservicepublic/callback")
  end
  let!(:agent) do
    create(:agent, basic_role_in_organisations: [organisation], rdv_notifications_level: :all)
  end
  let!(:motif) { create(:motif, service: agent.services.first, organisation: organisation, location_type: :public_office) }
  let!(:lieu) { create(:lieu, organisation: organisation) }

  let!(:user) do
    create(:user, :unregistered, organisations: [organisation]) # créé par appel d'api par l'appli qui s'intègre avec nous
  end
  let(:rdv_plan) do
    create(:rdv_plan,
           user: user,
           planning_agent: agent,
           return_url: "https://demo.demarches-simplifiees.fr/callback/123",
           oauth_application: application)
  end

  before do
    stub_netsize_ok
    login_as(agent, scope: :agent)
  end

  it "permet de prendre un rendez-vous", js: true do
    visit agents_rdv_plan_path(rdv_plan.id)
    find('.fc-timegrid-slot-lane[data-time="08:30:00"]').click # Click on the agenda
    expect(page).to have_content "Nouveau"
    expect(rdv_plan.reload.starts_at).to be_present

    find("label", text: "Sur place").click
    click_on "Continuer"
    expect(page).to have_content "Motif du rendez-vous "
    click_on "Continuer"

    # On a sélectionné le premier créneau visible du calendrier, qui est donc dans le passé
    # Hack : on modifie à la main le starts_at
    rdv_plan.update!(starts_at: 2.weeks.from_now)

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

    perform_enqueued_jobs
    emails = ActionMailer::Base.deliveries
    expect(emails.size).to eq(2)
    expect(emails.map { [_1.to, _1.subject] }).to include([["newaddress@exemple.com"], a_string_matching(/RDV confirmé le/)])
    expect(emails.map { [_1.to, _1.subject] }).to include([[agent.email], a_string_matching(/Nouveau RDV ajouté sur votre agenda/)])

    expect(page).to have_content("Retour sur Démarches Simplifiées")
  end

  context "quand l'agent n'appartient à aucune organisation" do
    # Ça arrive s'il n'a pas encore fait d'ouverture de compte avec notre équipe déploiement, ou qu'il n'a pas été invité à rejoindre son organisation par ses collègues
    let!(:agent) do
      create(:agent, basic_role_in_organisations: [])
    end

    it "redirige vers la page qui permet de corriger cette situation" do
      visit agents_rdv_plan_path(rdv_plan.id)
      expect(page).to have_content("Vos collègues peuvent vous inviter")
      expect(page).to have_content("Vous pouvez demander à ouvrir un espace pour votre organisation.")
    end
  end
end
