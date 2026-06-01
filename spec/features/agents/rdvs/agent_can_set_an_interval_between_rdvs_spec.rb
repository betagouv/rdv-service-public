RSpec.describe "un agent peut définir un intervalle entre chaque RDV" do
  before { travel_to(Time.zone.parse("2026-05-29 08:00")) }

  describe "configuration de l'intervalle" do
    let!(:agent) { create(:agent, basic_role_in_organisations: [motif.organisation]) }
    let!(:motif) { create(:motif, :by_phone, default_duration_in_min: 30) }

    it "fonctionne" do
      login_as(agent, scope: :agent)
      visit new_admin_organisation_planning_plage_ouverture_path(organisation_id: motif.organisation)
      select("10 min.", from: "Intervalle entre chaque rendez-vous")
      click_on "Créer la plage d'ouverture"
      expect(PlageOuverture.last.minutes_after_rdvs).to eq(10)
    end
  end

  describe "prise de RDV par un agent (classique)" do
    let!(:agent) { create(:agent, basic_role_in_organisations: [motif.organisation]) }
    let!(:motif) { create(:motif, :by_phone, default_duration_in_min: 30) }
    let!(:plage) do
      create(:plage_ouverture, organisation: motif.organisation, agent:, motifs: [motif],
                               minutes_after_rdvs: 10, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(12))
    end
    let!(:user) { create(:user, organisations: [motif.organisation]) }

    it "respecte l'intervalle dans le calcul de créneaux et enregistre l'intervalle dans le RDV créé" do
      login_as(agent, scope: :agent)
      visit admin_organisation_creneaux_search_path(organisation_id: motif.organisation, user_ids: [user.id])
      select(motif.name, from: "motif_id")
      click_button("Afficher les créneaux")
      expect(page.all("a.creneau .strong").map(&:text)).to eq(["09:00", "09:40", "10:20", "11:00"])

      click_on("10:20")
      click_on("Continuer")
      click_on("Continuer")
      click_on("Confirmer le RDV")
      expect(Rdv.last).to have_attributes(minutes_after_rdv: 10)
    end
  end

  describe "prise de RDV par un usager" do
    let!(:agent) { create(:agent, basic_role_in_organisations: [motif.organisation]) }
    let!(:motif) { create(:motif, :by_phone, bookable_by: :everyone, default_duration_in_min: 30) }
    let!(:plage) do
      create(:plage_ouverture, organisation: motif.organisation, agent:, motifs: [motif],
                               minutes_after_rdvs: 10, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(12))
    end

    it "respecte l'intervalle dans le calcul de créneaux et enregistre l'intervalle dans le RDV créé" do
      visit "/org/#{motif.organisation.public_link_id}"
      click_on motif.name
      expect(page.all("a[autofocus]").map(&:text)).to eq(["09:00", "09:40", "10:20", "11:00"])

      click_on("10:20")
      fill_in("Prénom", with: "Patricia")
      fill_in("Nom", with: "Duroy")
      fill_in("Adresse email", with: "patricia_duroy@demo.rdv-solidarites.fr")
      click_on("Recevoir un code de connexion")
      fill_in("login_code_code", with: LoginCode.last.code)
      click_on("Valider")
      fill_in("Téléphone", with: "0611223344")
      click_on("Continuer")
      click_on("Continuer")
      click_on("Confirmer mon RDV")
      expect(Rdv.last).to have_attributes(minutes_after_rdv: 10)
    end

    context "via un prescripteur" do
      it "respecte l'intervalle dans le calcul de créneaux et enregistre l'intervalle dans le RDV créé" do
        visit "/org/#{motif.organisation.public_link_id}"
        click_on motif.name
        expect(page.all("a[autofocus]").map(&:text)).to eq(["09:00", "09:40", "10:20", "11:00"])

        click_on("10:20")
        click_on("Je suis un prescripteur qui oriente un bénéficiaire")
        fill_in("Votre prénom", with: "Agent")
        fill_in("Votre nom", with: "Prescripteur")
        fill_in("Votre email professionnel", with: "prenom.prescripteur@domaine.fr")
        click_on("Continuer")
        fill_in("Prénom", with: "Patricia")
        fill_in("Nom d’usage", with: "Duroy")
        fill_in("Téléphone mobile", with: "0611223344")
        click_on("Confirmer le rendez-vous")
        expect(Rdv.last).to have_attributes(minutes_after_rdv: 10)
      end
    end
  end

  describe "prise de RDV par agent prescripteur" do
    let!(:territory) { create(:territory) }
    let!(:orga_du_rdv) { create(:organisation, territory:) }
    let!(:orga_du_prescripteur) { create(:organisation, territory:) }
    let!(:agent_du_rdv) { create(:agent, basic_role_in_organisations: [orga_du_rdv]) }
    let!(:agent_prescripteur) { create(:agent, basic_role_in_organisations: [orga_du_prescripteur]) }
    let!(:motif) { create(:motif, :by_phone, default_duration_in_min: 30, organisation: orga_du_rdv) }
    let!(:plage) do
      create(:plage_ouverture, organisation: orga_du_rdv, agent: agent_du_rdv, motifs: [motif],
                               minutes_after_rdvs: 10, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(12))
    end
    let!(:user) { create(:user, organisations: [motif.organisation]) }

    before do
      stub_request(:get, "https://data.geopf.fr/geocodage/search/?q=#{user.address.gsub(' ', '%20')}")
        .to_return(body: file_fixture("geocode_result.json").read)
    end

    it "respecte l'intervalle dans le calcul de créneaux et enregistre l'intervalle dans le RDV créé" do
      login_as(agent_prescripteur, scope: :agent)
      visit admin_organisation_creneaux_search_path(organisation_id: orga_du_prescripteur, user_ids: [user.id])
      click_link "Élargir la recherche"
      click_on motif.name
      click_on orga_du_rdv.name
      expect(page.all("a[autofocus]").map(&:text)).to eq(["09:00", "09:40", "10:20", "11:00"])

      click_on("10:20")
      click_on("Confirmer le rdv")
      expect(Rdv.last).to have_attributes(minutes_after_rdv: 10)
    end
  end
end
