RSpec.describe "Organisation selection (when motif does not require lieu)" do
  before { travel_to(Time.zone.parse("2024-01-08 08:00")) }

  let!(:service_social) { create(:service, name: "Service Social") }
  let!(:drome) { create(:territory, name: "Drôme", departement_number: "26") }

  let!(:orga_crest) { create(:organisation, territory: drome, name: "CMS Crest") }
  let!(:orga_nyons) { create(:organisation, territory: drome, name: "CMS Nyons") }
  let!(:orga_die)   { create(:organisation, territory: drome, name: "CMS Die") }

  let!(:motif_crest) { create(:motif, :by_phone, organisation: orga_crest, name: "Je souhaite être rappelé par le service social", service: service_social) }
  let!(:motif_nyons) { create(:motif, :by_phone, organisation: orga_nyons, name: "Je souhaite être rappelé par le service social", service: service_social) }
  let!(:motif_die)   { create(:motif, :by_phone, organisation: orga_die,   name: "Je souhaite être rappelé par le service social", service: service_social) }

  let!(:plage_crest_dans_3_semaines) { create(:plage_ouverture, first_day: 3.weeks.from_now, motifs: [motif_crest]) }
  let!(:plage_nyons_dans_2_semaines) { create(:plage_ouverture, first_day: 2.weeks.from_now, motifs: [motif_nyons]) }
  let!(:plage_die_dans_4_semaines)   { create(:plage_ouverture, first_day: 4.weeks.from_now, motifs: [motif_die]) }

  it "displays organisations ordered by first availability" do
    visit prendre_rdv_path(service_id: service_social.id, departement: drome.departement_number, motif_name_with_location_type: motif_crest.name_with_location_type)

    expect(page.body).to match(/CMS Nyons.*CMS Crest.*CMS Die/)
  end
end
