RSpec.describe "Agents can configure online booking" do
  let!(:organisation) { create(:organisation) }
  let!(:agent) { create(:agent, :cnfs, admin_role_in_organisations: [organisation]) }

  context "motif individuel" do
    let!(:motif) do
      create(:motif, organisation: organisation, service: agent.services.first, bookable_by: :agents, collectif: false, name: "Motif individuel")
    end

    it "displays the motif's status" do
      login_as(agent, scope: :agent)
      visit admin_organisation_online_booking_path(organisation)

      # On a 3 croix qui indiquent respectivement :
      # - le motif n'est pas réservable en ligne
      # - c'est parce que l'option n'a pas été activée via le formulaire du motif
      # - il n'y a pas de plages d'ouverture
      expect(page).to have_css("i.fa-regular.fa-circle-xmark.color-scheme-red", count: 3)

      expect(page).to have_content("Ce motif n'est pas réservable en ligne")
      expect(page).to have_link("modifier")
      expect(page).to have_content("Pas de plages d'ouverture")

      motif.update!(bookable_by: :everyone)

      visit admin_organisation_online_booking_path(organisation)
      expect(page).to have_content("Réservable en ligne")

      expect(page).to have_css("i.fa-solid.fa-circle-check.color-scheme-green", count: 1)
      expect(page).to have_css("i.fa-regular.fa-circle-xmark.color-scheme-red", count: 2)

      click_link("ajouter")
      expect(page).to have_checked_field(motif.name)

      create(:plage_ouverture, motifs: [motif], agent: agent, organisation: organisation)

      visit admin_organisation_online_booking_path(organisation)
      expect(page).to have_css("i.fa-solid.fa-circle-check.color-scheme-green", count: 3)
      expect(page).not_to have_css("i.fa-regular.fa-circle-xmark.color-scheme-red")
      expect(page).to have_content("1 plage d'ouverture")
    end

    it "doesn't show plages d'ouverture in the past" do
      create(:plage_ouverture, motifs: [motif], agent: agent, organisation: organisation, first_day: 20.days.from_now)
      create(:plage_ouverture, motifs: [motif], agent: agent, organisation: organisation, first_day: 10.days.ago)

      login_as(agent, scope: :agent)
      visit admin_organisation_online_booking_path(organisation)

      expect(page).to have_content("1 plage d'ouverture")
    end
  end

  context "motif collectif" do
    let!(:motif) do
      create(:motif, organisation: organisation, service: agent.services.first, collectif: true, name: "Motif collectif")
    end

    it "displays the motif's status" do
      login_as(agent, scope: :agent)

      visit admin_organisation_online_booking_path(organisation)
      expect(page).to have_css("i.fa-solid.fa-circle-check.color-scheme-green", count: 1)
      expect(page).to have_css("i.fa-regular.fa-circle-xmark.color-scheme-red", count: 2)
      expect(page).to have_content("Réservable en ligne")
      expect(page).to have_content("Aucun rendez-vous avec des places disponibles")

      create(:rdv, motif: motif, max_participants_count: 5)

      visit admin_organisation_online_booking_path(organisation)
      expect(page).to have_css("i.fa-solid.fa-circle-check.color-scheme-green", count: 3)
      expect(page).not_to have_css("i.fa-regular.fa-circle-xmark.color-scheme-red")
      expect(page).to have_content("1 rendez-vous avec des places disponibles")
    end
  end

  describe "booking link" do
    context "when organisation is sectorized" do
      before do
        sector = create(:sector, territory: organisation.territory)
        create(:sector_attribution, :level_organisation, sector: sector, organisation: organisation)
        create(:motif, :sectorisation_level_organisation, organisation: organisation)
      end

      it "points to the public booking home page" do
        login_as(agent, scope: :agent)
        visit admin_organisation_online_booking_path(organisation)
        expect(find("input#booking_link").value).to eq("http://www.rdv-solidarites-test.localhost:#{Capybara.server_port}/prendre_rdv")
      end
    end

    context "when organisation is not sectorized" do
      it "points to the public booking home page" do
        login_as(agent, scope: :agent)
        visit admin_organisation_online_booking_path(organisation)
        expect(find("input#booking_link").value).to eq("http://www.rdv-solidarites-test.localhost:#{Capybara.server_port}/org/#{organisation.id}/#{organisation.slug}")
      end
    end
  end
end
