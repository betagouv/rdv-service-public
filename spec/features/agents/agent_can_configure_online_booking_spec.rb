# frozen_string_literal: true

describe "Agents can configure online booking" do
  let!(:organisation) { create(:organisation) }
  let!(:agent) { create(:agent, :cnfs, admin_role_in_organisations: [organisation]) }

  context "motif individuel" do
    let!(:motif) do
      create(:motif, organisation: organisation, service: agent.service, reservable_online: false, collectif: false, name: "Motif individuel")
    end

    it "displays the motif's status" do
      login_as(agent, scope: :agent)
      visit admin_organisation_online_booking_path(organisation)

      expect(page).to have_css("i.fa-regular.fa-circle-xmark.color-scheme-red", count: 3)

      expect(page).to have_content("Ce motif n'est pas réservable en ligne")
      expect(page).to have_link("modifier")
      expect(page).to have_content("Pas de plages d'ouverture")
      expect(page).to have_link("ajouter")

      motif.update!(reservable_online: true)

      visit admin_organisation_online_booking_path(organisation)
      expect(page).to have_css("i.fa-solid.fa-circle-check.color-scheme-green", count: 1)
      expect(page).to have_css("i.fa-regular.fa-circle-xmark.color-scheme-red", count: 2)
      expect(page).to have_content("Réservable en ligne")

      create(:plage_ouverture, motifs: [motif], agent: agent, organisation: organisation)

      visit admin_organisation_online_booking_path(organisation)
      expect(page).to have_content("1 plage d'ouverture")
      expect(page).to have_css("i.fa-solid.fa-circle-check.color-scheme-green", count: 3)
      expect(page).not_to have_css("i.fa-regular.fa-circle-xmark.color-scheme-red")
    end
  end

  context "motif collectif" do
    let!(:motif) do
      create(:motif, organisation: organisation, service: agent.service, reservable_online: true, collectif: true, name: "Motif collectif")
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
end
