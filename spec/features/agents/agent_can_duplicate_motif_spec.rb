RSpec.describe "agent can duplicate motif" do
  let(:territory) { create(:territory).tap { _1.motif_categories << create(:motif_category, name: "Cat de motif") } }
  let(:organisation) { create(:organisation, territory: territory) }
  let(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }
  let(:motif_service) { create(:service, name: "Service du motif à dupliquer") }

  let(:existing_motif) do
    create(
      :motif,
      organisation: organisation,
      motif_category: territory.motif_categories.first,
      service: motif_service,
      name: "Motif à créer 18 fois",
      default_duration_in_min: 28,
      color: "#00ffff",
      location_type: Motif.location_types[:phone],
      bookable_by: Motif.bookable_bies[:agents_and_prescripteurs],
      min_public_booking_delay: 6.hours,
      max_public_booking_delay: 3.months,
      rdvs_editable_by_user: true,
      sectorisation_level: Motif::SECTORISATION_LEVEL_ORGANISATION,
      for_secretariat: true,
      visibility_type: Motif::VISIBLE_AND_NOT_NOTIFIED,
      restriction_for_rdv: "Réservé aux personnes factices",
      instruction_for_rdv: "Venez très très très tôt",
      custom_cancel_warning_message: "Êtes-vous sûr d'être certain ?"
    )
  end

  before do
    organisation.territory.services << motif_service
  end

  it "works" do
    login_as(agent, scope: :agent)
    visit admin_organisation_motif_path(organisation, existing_motif)
    click_on "Dupliquer"

    expect(page).not_to have_content("Créer le motif dans cette organisation")
    choose :motif_location_type_home # Je veux créer le même motif mais en version à domicile
    expect { click_on "Créer le motif" }.to change(Motif, :count).by(1)

    expected_attributes = existing_motif.attributes.symbolize_keys.merge(
      id: be_a(Integer),
      created_at: be_within(1.second).of(Time.zone.now),
      updated_at: be_within(1.second).of(Time.zone.now),
      location_type: "home"
    )
    expect(Motif.last).to have_attributes(expected_attributes)
  end

  context "when agent is in multiple organisations" do
    let(:other_organisation) { create(:organisation, name: "Mon autre orga", territory: territory) }
    let!(:motif_in_other_orga) do
      create(:motif, organisation: other_organisation, name: existing_motif.name, service: existing_motif.service, location_type: existing_motif.location_type)
    end

    before do
      agent.roles.create!(organisation: other_organisation, access_level: AgentRole::ACCESS_LEVEL_ADMIN)
    end

    it "allows duplicating in another organisation" do
      login_as(agent, scope: :agent)
      visit admin_organisation_motif_path(organisation, existing_motif)
      click_on "Dupliquer"
      select "Mon autre orga", from: :motif_organisation_id

      # En cas d'erreur de validation (ici parce qu'il existe déjà un motif avec le meme nom),
      # on continue d'afficher la page de duplication
      click_on "Créer le motif"

      expect(page).to have_content "Duplication du motif"
      fill_in("Nom du motif", with: "Suivi de dossier")

      expect { click_on "Créer le motif" }.to change(Motif, :count).by(1)

      expected_attributes = existing_motif.attributes.symbolize_keys.merge(
        id: be_a(Integer),
        created_at: be_within(1.second).of(Time.zone.now),
        updated_at: be_within(1.second).of(Time.zone.now),
        name: "Suivi de dossier",
        organisation_id: other_organisation.id
      )
      expect(Motif.last).to have_attributes(expected_attributes)

      # Rediriger vers la liste des motifs de l'autre orga
      expect(page).to have_current_path("/admin/organisations/#{other_organisation.id}/motifs")
    end
  end
end
