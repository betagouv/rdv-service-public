RSpec.describe "prescripteur can create RDV for a user" do
  before do
    travel_to(Time.zone.parse("2022-11-07 15:00"))
  end

  let!(:territory) { create(:territory, departement_number: "75") }
  let!(:organisation) { create(:organisation, territory: territory) }
  let!(:agent) { create(:agent, :cnfs, admin_role_in_organisations: [organisation], rdv_notifications_level: "all") }
  let(:bookable_by) { "everyone" }
  let!(:motif) do
    create(:motif, organisation: organisation, service: agent.services.first, bookable_by: bookable_by, instruction_for_rdv: "Instructions après confirmation", name: "Formation emails")
  end
  let!(:lieu) { create(:lieu, organisation: organisation, name: "Bureau") }
  let!(:plage_ouverture) { create(:plage_ouverture, organisation: organisation, agent: agent, motifs: [motif], lieu: lieu) }

  it "works" do
    visit "http://www.rdv-aide-numerique-test.localhost/org/#{organisation.id}"

    click_on "Formation emails" # choix du motif
    click_on "Prochaine disponibilité le" # choix du lieu
    click_on "08:00" # choix du créneau
    click_on "Je suis un prescripteur qui oriente un bénéficiaire" # page de login

    fill_in "Votre prénom", with: "Alex"
    fill_in "Votre nom", with: "Prescripteur"
    fill_in "Votre email professionnel", with: "alex@prescripteur.fr"
    fill_in "Votre numéro de téléphone", with: "0611223344"
    click_on "Continuer"

    expect(page).to have_content("Prescripteur : Alex PRESCRIPTEUR")
    fill_in "Prénom", with: "Patricia"
    fill_in "Nom", with: "Duroy"
    fill_in "Téléphone", with: "0611223344"

    # On simule que le créneau choisi est simultanément pris par quelqu'un d'autre
    create(:rdv, starts_at: Time.zone.local(2022, 11, 15, 8, 0, 0), motif: motif, agents: [agent], lieu: lieu)
    click_on "Confirmer le rendez-vous"
    expect(page).to have_content("Ce créneau n'est plus disponible. Veuillez en choisir un autre.")
    # Dans ce cas, retour à l'étape de choix du lieu
    click_on "Prochaine disponibilité le"
    click_on "08:45"

    # On constate que le formulaire de prescripteur est pré-rempli
    expect(page).to have_field("Votre prénom", with: "Alex")
    expect(page).to have_field("Votre nom", with: "Prescripteur")
    click_on "Continuer"

    expect(page).to have_content("Prescripteur : Alex PRESCRIPTEUR")
    fill_in "Prénom", with: "Patricia"
    fill_in "Nom", with: "Duroy"
    click_on "Confirmer le rendez-vous"
    expect(page).to have_content("Sans numéro de téléphone, aucune notification ne sera envoyée au bénéficiaire")
    click_on "Annuler et modifier"
    fill_in "Téléphone", with: "0123456789"

    click_on "Confirmer le rendez-vous"
    expect(page).to have_content("Téléphone ne permet pas de recevoir des SMS")
    fill_in "Téléphone", with: "0611223344"

    expect { click_on "Confirmer le rendez-vous" }.to change(Rdv, :count).by(1).and(change(User, :count).by(1))

    expect(page).to have_content("Rendez-vous confirmé")
    expect(page).to have_content("Patricia DUROY")
    expect(page).to have_content("Le mardi 15 novembre 2022 à 08h45")
    expect(page).to have_content("Bureau")
    expect(page).to have_content("Instructions après confirmation")

    created_rdv = Rdv.last
    expect(created_rdv.agents).to eq([agent])

    expect(created_rdv.participations.size).to eq(1)

    created_participation = created_rdv.participations.first
    created_user = created_participation.user

    expect(created_user).to have_attributes(
      full_name: "Patricia DUROY",
      created_through: "prescripteur",
      phone_number: "0611223344",
      organisation_ids: [organisation.id]
    )
    expect(created_participation.created_by).to have_attributes(
      first_name: "Alex",
      last_name: "Prescripteur",
      email: "alex@prescripteur.fr",
      phone_number: "0611223344"
    )
    expect(created_rdv.created_by_prescripteur?).to be(true)
    expect(created_rdv.participations.first.created_by_prescripteur?).to be(true)

    perform_enqueued_jobs(queue: "mailers")
    expect(email_sent_to(agent.email).subject).to include("Nouveau RDV ajouté sur votre agenda RDV Solidarités")
    expect(email_sent_to("alex@prescripteur.fr").subject).to include("RDV confirmé")
    expect(email_sent_to("alex@prescripteur.fr").body).to include("RDV Aide Numérique")

    expect(enqueued_jobs.first["job_class"]).to eq("SmsJob")
    expect(enqueued_jobs.first["arguments"][0]["phone_number"]).to eq("+33611223344")
  end

  def fill_address_form
    fill_in :search_where, with: "21 rue des Ardennes, 75019 Paris"

    # fake address autocomplete
    page.execute_script("document.querySelector('#search_departement').value = '#{motif.organisation.territory.departement_number}'")
    page.execute_script("document.querySelector('#search_submit').disabled = false")

    click_on("Rechercher")
  end

  context "when the prescripteur info isn't filled in" do
    it "doesn't shows error messages and doesn't allow continuing" do
      visit "http://www.rdv-aide-numerique-test.localhost/org/#{organisation.id}"

      click_on "Formation emails" # choix du motif
      click_on "Prochaine disponibilité le" # choix du lieu
      click_on "08:00" # choix du créneau
      click_on "Je suis un prescripteur qui oriente un bénéficiaire" # page de login

      fill_in "Votre prénom", with: "Alex"
      fill_in "Votre nom", with: "  "
      fill_in "Votre email professionnel", with: "alex@prescripteur.fr"
      fill_in "Votre numéro de téléphone", with: "0611223344"
      click_on "Continuer"

      expect(page).to have_content("Vos coordonnées de prescripteur")
      expect(page).to have_content("Nom d’usage doit être rempli(e)")
      expect(page).to have_content("Veuillez compléter tous les champs obligatoires")
    end
  end

  context "when a similar user already exists", js: true do
    let!(:user) do
      create(:user, first_name: "Patricia", last_name: "Duroy", phone_number: "0611223344")
    end

    def fill_prescripteur_form
      fill_in "Votre prénom", with: "Alex"
      fill_in "Votre nom", with: "Prescripteur"
      fill_in "Votre email professionnel", with: "alex@prescripteur.fr"
      fill_in "Votre numéro de téléphone", with: "0655443322"
      click_on "Continuer"
    end

    it "doesn't create a new one but adds the user to the organisation" do
      visit "http://www.rdv-solidarites-test.localhost/prendre_rdv_prescripteur"
      # On vérifie que le message d'incitation à la prescription interne ne s'affiche pas (l'agent n'est pas connecté)
      expect(page).not_to have_content("Nouvelle fonctionnalité :\nla prescription dans l'espace agent")

      fill_address_form

      click_on "Formation emails" # choix du motif
      click_on "Prochaine disponibilité le", match: :first # choix du lieu
      click_on "08:00" # choix du créneau

      fill_prescripteur_form

      fill_in "Prénom", with: "Patricia"
      fill_in "Nom", with: "DUROY"
      # Le format du numéro de téléphone n'est pas exactement le même que celui en base
      fill_in "Téléphone", with: "06 11 22 33 44"

      expect { click_on "Confirmer le rendez-vous" }.to change(Rdv, :count).by(1)
        .and(change(User, :count).by(0))
        .and(change(UserProfile, :count).by(1))

      expect(UserProfile.last).to have_attributes(
        user: user,
        organisation: motif.organisation
      )
    end

    context "and is already part of the organisation" do
      before do
        create(:user_profile, organisation: organisation, user: user)
      end

      it "doesn't create a duplicate profile" do
        visit "http://www.rdv-solidarites-test.localhost/prendre_rdv_prescripteur"

        fill_address_form

        click_on "Formation emails" # choix du motif
        click_on "Prochaine disponibilité le", match: :first # choix du lieu
        click_on "08:00" # choix du créneau

        fill_prescripteur_form

        fill_in "Prénom", with: "Patricia"
        fill_in "Nom", with: "DUROY"
        # Le format du numéro de téléphone n'est pas exactement le même que celui en base
        fill_in "Téléphone", with: "06 11 22 33 44"

        expect { click_on "Confirmer le rendez-vous" }.to change(Rdv, :count).by(1).and(change(UserProfile, :count).by(0))
      end
    end
  end

  context "when using the prescripteur route" do
    let!(:lieu2) { create(:lieu, organisation: organisation, name: "Autre bureau") }
    let!(:plage_ouverture2) { create(:plage_ouverture, organisation: organisation, agent: agent, motifs: [motif], lieu: lieu2) }
    let(:bookable_by) { "agents_and_prescripteurs" }

    it "goes directly to prescripteur forms after creneau selection ands keeps the prescripteur param when navigating backwards", js: true do
      visit "http://www.rdv-solidarites-test.localhost/prendre_rdv_prescripteur"

      fill_address_form

      click_on "Formation emails" # choix du motif
      click_on "Prochaine disponibilité le", match: :first # choix du lieu
      click_on "08:00" # choix du créneau

      expect(page).to have_content("Vos coordonnées de prescripteur")

      find_all("a", text: "modifier").last.click # Retour en arrière au choix de créneau

      expect(page).to have_content("Sélectionnez un créneau")

      click_on(lieu.name)

      expect(page).to have_content("Sélectionnez un lieu de RDV")
      click_on("Prochaine disponibilité", match: :first)

      click_on "08:00" # choix du créneau

      expect(page).to have_content("Vos coordonnées de prescripteur")
    end
  end

  context "when using the prescripteur route for a logged agent" do
    let!(:agent_prescripteur) { create(:agent, admin_role_in_organisations: [organisation2]) }
    let(:sector) { build(:sector, territory: territory) }
    let!(:organisation2) { create(:organisation, territory: territory) }

    before do
      login_as(agent_prescripteur, scope: :agent)
    end

    it "display internal prescription incitation and correctly redirect to the feature", js: true do
      visit "http://www.rdv-solidarites-test.localhost/prendre_rdv_prescripteur"
      expect(page).to have_content("Nouvelle fonctionnalité :\nla prescription dans l'espace agent")

      fill_address_form

      click_on "Formation emails" # choix du motif
      click_on "Prochaine disponibilité le", match: :first
      click_on "08:00"

      expect(page).to have_content("Vos coordonnées de prescripteur")
      expect(page).to have_content("Nouvelle fonctionnalité : Pour ne pas avoir à remplir ce formulaire pour chaque " \
                                   "nouveau rendez-vous et réduire les doublons, vous pouvez utiliser la prescription dans l'espace agent")
      expect(page).to have_link("en cliquant ici")
      click_on "en cliquant ici"
      expect(page).to have_current_path("/admin/organisations/#{agent_prescripteur.organisations.find_by(territory: territory).id}/prescription/user_selection", ignore_query: true)
      expect(page).to have_content(lieu.name)
      expect(page).to have_content("08h00")
      expect(page).to have_content(motif.name)
    end

    it "doesn't display internal prescription incitation when the agent doesn't belongs to a territory with opened motifs" do
      organisation.motifs.destroy_all
      visit "http://www.rdv-solidarites-test.localhost/prendre_rdv_prescripteur"
      expect(page).not_to have_content("Nouvelle fonctionnalité :\nla prescription dans l'espace agent")
    end

    context "when the agent belongs to a sectorized territory" do
      before do
        allow_any_instance_of(Territory).to receive(:sectorized?).and_return(true) # rubocop:disable RSpec/AnyInstance
      end

      it "doesn't display internal prescription incitation link when territory is sectorized", js: true do
        visit "http://www.rdv-solidarites-test.localhost/prendre_rdv_prescripteur"
        fill_address_form
        click_on "Formation emails" # choix du motif
        click_on "Prochaine disponibilité le", match: :first
        click_on "08:00"
        expect(page).to have_content("Nouvelle fonctionnalité : Pour ne pas avoir à remplir ce formulaire pour chaque " \
                                     "nouveau rendez-vous et réduire les doublons, vous pouvez utiliser la prescription dans l'espace agent.")
        expect(page).not_to have_link("en cliquant ici")
      end
    end
  end

  context "when going directly to a prescripteur form without having selected a creneau" do
    it "redirects to the homepage with an error message" do
      visit "http://www.rdv-solidarites-test.localhost/prescripteur/new_prescripteur"
      expect(page).to have_content("Nous n'avons pas trouvé le créneau pour lequel vous souhaitiez prendre rendez-vous.")
      expect(sentry_events.last.message).to eq("Prescripteur sans infos de creneau. Voir https://github.com/betagouv/rdv-solidarites.fr/issues/3420")
    end
  end
end
