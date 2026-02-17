RSpec.describe Users::RdvBuilder do
  let!(:organisation) { create(:organisation) }
  let!(:user) { create(:user) }
  let!(:user_for_rdv) { create(:user) }
  let!(:motif) { create(:motif, organisation: organisation, default_duration_in_min: 30) }
  let!(:lieu) { create(:lieu, organisation: organisation) }
  let!(:creneau) { build(:creneau, :respects_booking_delays, motif: motif, starts_at: Time.zone.parse("2020-10-20 09h30")) }
  let!(:plage_ouverture) { create(:plage_ouverture, motifs: [motif], lieu: lieu, organisation: organisation) }

  let(:mock_geo_search) { instance_double(Users::GeoSearch) }
  let(:attributes) do
    {
      starts_at: creneau.starts_at,
      motif_id: motif.id,
      lieu_id: lieu.id,
      user_ids: [user_for_rdv.id],
      departement: "62",
      city_code: "62100",
    }
  end

  it "construit un RDV et un créneau" do
    returned_creneau = Creneau.new

    allow(Users::GeoSearch).to receive(:new)
      .with(departement: "62", city_code: "62100")
      .and_return(mock_geo_search)
    allow(CreneauxSearch::ForUser).to receive(:creneau_for).with(
      user: user,
      motif: motif,
      lieu: lieu,
      starts_at: Time.zone.parse("2020-10-20 09h30"),
      geo_search: mock_geo_search,
      duration_in_min: 30
    ).and_return(returned_creneau)
    rdv_wizard = described_class.new(user, attributes)
    expect(rdv_wizard.rdv.user_ids).to eq [user_for_rdv.id]
    expect(rdv_wizard.creneau).to eq returned_creneau
  end

  it "avec un duration_in_min différent de celui du motif" do
    returned_creneau = Creneau.new
    allow(Users::GeoSearch).to receive(:new)
      .with(departement: "62", city_code: "62100")
      .and_return(mock_geo_search)
    allow(CreneauxSearch::ForUser).to receive(:creneau_for).with(
      user: user,
      motif: motif,
      lieu: lieu,
      starts_at: Time.zone.parse("2020-10-20 09h30"),
      geo_search: mock_geo_search,
      duration_in_min: 60
    ).and_return(returned_creneau)
    rdv_wizard = described_class.new(user, attributes.merge(duration: 60))
    expect(rdv_wizard.rdv.user_ids).to eq [user_for_rdv.id]
    expect(rdv_wizard.creneau).to eq returned_creneau
  end

  context "le motif_id ne correspond à aucun motif existant" do
    let(:attributes) do
      {
        starts_at: Time.zone.parse("2020-10-20 09h30"),
        motif_id: 0,
        lieu_id: lieu.id,
        user_ids: [user_for_rdv.id],
        departement: "62",
        city_code: "62100",
      }
    end

    it "ne lève pas d'erreurs" do
      rdv_builder = described_class.new(user, attributes)
      expect(rdv_builder.rdv.motif).to be_nil
      expect(rdv_builder.rdv.organisation_id).to be_nil
      expect(rdv_builder.rdv.duration_in_min).to be_nil
      expect(rdv_builder.creneau).to be_nil
    end
  end

  context "le lieu_id ne correspond à aucun lieu existant" do
    let(:attributes) do
      {
        starts_at: creneau.starts_at,
        motif_id: motif.id,
        lieu_id: 0,
        user_ids: [user_for_rdv.id],
        departement: "62",
        city_code: "62100",
      }
    end

    it "ne lève pas d'erreurs" do
      rdv_builder = described_class.new(user, attributes)
      expect(rdv_builder.lieu).to be_nil
      expect(rdv_builder.creneau).to be_nil
    end
  end

  context "starts_at est nil" do
    let(:attributes) do
      {
        starts_at: nil,
        motif_id: motif.id,
        lieu_id: lieu.id,
        user_ids: [user_for_rdv.id],
        departement: "62",
        city_code: "62100",
      }
    end

    it "ne lève pas d'erreurs" do
      rdv_builder = described_class.new(user, attributes)
      expect(rdv_builder.creneau).to be_nil
    end
  end

  context "ants_pre_demandes_count présent mais motif inexistant" do
    let(:attributes) do
      {
        starts_at: Time.zone.parse("2020-10-20 09h30"),
        motif_id: 0,
        lieu_id: lieu.id,
        user_ids: [user_for_rdv.id],
        departement: "62",
        city_code: "62100",
        ants_pre_demandes_count: "2",
      }
    end

    it "ne lève pas d'erreurs" do
      rdv_builder = described_class.new(user, attributes)
      expect(rdv_builder.duration_in_min).to be_nil
    end
  end

  context "Rdv collectif - bookable by agents and prescripteurs" do
    let(:motif) { create(:motif, :at_public_office, organisation: organisation, bookable_by: :agents_and_prescripteurs, collectif: true) }
    let!(:rdv) { create(:rdv, motif: motif, organisation: organisation) }
    let(:attributes) { { rdv_collectif_id: rdv.id } }

    it "trouve le RDV existant" do
      expect(described_class.new(user_for_rdv, attributes).rdv).to eq(rdv)
    end
  end
end
