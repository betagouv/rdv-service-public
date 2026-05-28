RSpec.describe "un agent peut définir un intervalle entre chaque RDV" do
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

  describe "respect de l'intervalle dans le calcul de créneaux côté agent" do
    let!(:agent) { create(:agent, basic_role_in_organisations: [motif.organisation]) }
    let!(:motif) { create(:motif, :by_phone, default_duration_in_min: 30) }
    let!(:plage) do
      create(:plage_ouverture, organisation: motif.organisation, agent:, motifs: [motif],
                               minutes_after_rdvs: 10, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(12))
    end

    it "fonctionne" do
      login_as(agent, scope: :agent)
      visit admin_organisation_creneaux_search_path(organisation_id: motif.organisation)
      select(motif.name, from: "motif_id")
      click_button("Afficher les créneaux")
      expect(page.all("a.creneau .strong").map(&:text)).to eq(["09:00", "09:40", "10:20", "11:00"])
    end
  end

  describe "respect de l'intervalle dans le calcul de créneaux côté usager" do
    let!(:agent) { create(:agent, basic_role_in_organisations: [motif.organisation]) }
    let!(:motif) { create(:motif, :by_phone, bookable_by: :everyone, default_duration_in_min: 30) }
    let!(:plage) do
      create(:plage_ouverture, organisation: motif.organisation, agent:, motifs: [motif],
                               minutes_after_rdvs: 10, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(12))
    end

    it "fonctionne" do
      visit "/org/#{motif.organisation.public_link_id}"
      click_on motif.name
      expect(page.all("a[autofocus]").map(&:text)).to eq(["09:00", "09:40", "10:20", "11:00"])
    end
  end

  describe "respect de l'intervalle dans le calcul de créneaux côté agent prescripteur" do
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

    it "fonctionne" do
      login_as(agent_prescripteur, scope: :agent)
      visit admin_organisation_creneaux_search_path(organisation_id: orga_du_prescripteur)
      click_link "Élargir la recherche"
      click_on motif.name
      click_on orga_du_rdv.name
      expect(page.all("a[autofocus]").map(&:text)).to eq(["09:00", "09:40", "10:20", "11:00"])
    end
  end
end
