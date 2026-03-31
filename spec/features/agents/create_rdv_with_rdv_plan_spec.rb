RSpec.describe "Les agents peuvent prendre un rendez-vous en passant par l'interface de rdv_plan" do
  let!(:organisation) { create(:organisation, name: "CCAS de Montreuil") }
  let(:application) do
    create(:oauth_application,
           name: "Démarches Simplifiées",
           redirect_uri: "http://localhost:4567/omniauth/rdvservicepublic/callback\nhttp://demo.demarches-simplifiees.fr/omniauth/rdvservicepublic/callback")
  end
  let!(:agent) do
    create(:agent, basic_role_in_organisations: [organisation], rdv_notifications_level: :all)
  end
  let!(:motif) { create(:motif, organisation: organisation, location_type: :public_office) }
  let!(:lieu) { create(:lieu, organisation: organisation) }

  let!(:user) do
    create(:user, latest_login_at: nil, organisations: [organisation]) # créé par appel d'api par l'appli qui s'intègre avec nous
  end
  let(:rdv_plan) do
    create(:rdv_plan,
           user: user,
           rdv_agent: agent,
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
    expect(emails.map { [_1.to, _1.subject] }).to include([[agent.email], a_string_matching(/Nouveau RDV ajouté pour .+ sur votre agenda/)])

    expect(page).to have_content("Retour sur Démarches Simplifiées")
  end

  it "displays existing RDVs and absences", js: true do
    existing_rdv_this_week = create(:rdv, starts_at: Time.zone.now.beginning_of_week + 8.hours, agents: [agent], motif:, organisation:)
    existing_absence_next_week = create(:absence, first_day: Time.zone.now.beginning_of_week.to_date + 1.week, agent:)
    visit agents_rdv_plan_path(rdv_plan.id)
    expect(page).to have_content(existing_rdv_this_week.users.first.full_name)
    click_on("Semaine suivante")
    expect(page).to have_content(existing_absence_next_week.title)
  end

  context "quand l'usager a déjà une adresse email et qu'on veut la changer" do
    let(:rdv_plan) do
      create(:rdv_plan, user: user, motif: motif, location_type: :public_office, duration_in_minutes: 30,
                        rdv_agent: agent,
                        lieu: lieu,
                        starts_at: 2.days.from_now,
                        planning_agent: agent,
                        oauth_application: application)
    end

    context "et l'usager ne s'est jamais connecté" do
      let(:user) { create(:user, latest_login_at: nil, organisations: [organisation], email: "old_email@exemple.fr") }

      it "met à jour l'email" do
        visit edit_user_agents_rdv_plan_path(rdv_plan.id)
        fill_in("Email", with: "francis@exemple.fr")

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
        expect(user.reload.email).to eq "francis@exemple.fr"
      end
    end

    context "et l'usager a un compte devise" do
      let(:user) { create(:user, organisations: [organisation], email: "old_email@exemple.fr", phone_number: "0611223344") }

      it "affiche un avertissement mais permet la modification de l'email", js: true do
        visit edit_user_agents_rdv_plan_path(rdv_plan.id)
        expect(page).to have_field("Email", with: user.email)
        expect(page).to have_content("Cet usager utilise cette adresse email pour se connecter.")

        fill_in("Email", with: "nouvel_email@exemple.fr")
        fill_in("Téléphone", with: "0612345678")

        click_on "Confirmer le rendez-vous"
        expect(page).to have_content "Rendez-vous confirmé"

        expect(user.reload).to have_attributes(
          email: "nouvel_email@exemple.fr",
          phone_number: "0612345678"
        )
      end
    end
  end

  context "quand un autre usager utilise déjà cet email, et qu'on change l'email" do
    let(:user) { create(:user, latest_login_at: nil, organisations: [organisation], email: "francis@precedent.fr") }
    let!(:user_with_same_email) { create(:user, organisations: [organisation], email: "francis@exemple.fr") }
    let(:rdv_plan) do
      create(:rdv_plan, user: user, motif: motif, location_type: :public_office, duration_in_minutes: 30,
                        rdv_agent: agent,
                        lieu: lieu,
                        starts_at: 2.days.from_now,
                        planning_agent: agent,
                        oauth_application: application)
    end

    it "permet quand même de prendre le rendez-vous" do
      visit edit_user_agents_rdv_plan_path(rdv_plan.id)
      fill_in("Email", with: "francis@exemple.fr")

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
      expect(user.reload.email).to eq "francis@exemple.fr"

      # On a deux usagers avec le même email dans notre base, et c'est pas grave.
      expect(User.where(email: "francis@exemple.fr").count).to eq(2)
    end
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

  context "avec plusieurs motifs qui ont des location types différents" do
    let(:rdv_plan) do
      create(:rdv_plan,
             user: user,
             starts_at: 2.weeks.from_now,
             planning_agent: agent,
             rdv_agent: agent,
             return_url: "https://demo.demarches-simplifiees.fr/callback/123",
             oauth_application: application)
    end

    let!(:other_motif) do
      create(:motif, organisation: organisation, location_type: :phone, name: "Rappel téléphonique")
    end

    it "filtre les motifs par location type" do
      visit edit_modalites_agents_rdv_plan_path(rdv_plan.id)

      find("label", text: "Sur place").click
      click_on "Continuer"

      expect(page).to have_content "Motif du rendez-vous"

      expect(page).not_to have_content(other_motif.name)
    end
  end

  context "quand aucun motif n'est disponible pour l'agent choisi" do
    before { motif.archive }

    it "affiche un message qui explique le blocage" do
      visit edit_modalites_agents_rdv_plan_path(rdv_plan.id)

      expect(page).not_to have_content("Continuer")

      expect(page).to have_content "Vous devez d'abord créer un motif de rendez-vous pour l'organisation CCAS de Montreuil"
    end
  end
end
