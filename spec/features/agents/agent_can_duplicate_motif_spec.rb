RSpec.describe "agent can duplicate motif" do
  it "works" do
    organisation = create(:organisation)
    agent = create(:agent, admin_role_in_organisations: [organisation])
    motif_service = create(:service, name: "Service du motif à dupliquer")
    organisation.territory.services << motif_service

    existing_motif = create(
      :motif,
      organisation: organisation,
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

    login_as(agent, scope: :agent)
    visit admin_organisation_motif_path(organisation, existing_motif)
    click_on "Dupliquer"
    choose :motif_location_type_home # Je veux créer le même motif mais en version à domicile
    expect { click_on "Enregistrer" }.to change(Motif, :count).by(1)

    expected_attributes = existing_motif.attributes.symbolize_keys.merge(
      id: be_a(Integer),
      created_at: be_within(1.second).of(Time.zone.now),
      updated_at: be_within(1.second).of(Time.zone.now),
      location_type: "home"
    )
    expect(Motif.last).to have_attributes(expected_attributes)
  end
end
