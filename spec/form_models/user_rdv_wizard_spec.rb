describe UserRdvWizard do
  let!(:organisation) { create(:organisation) }
  let!(:user) { create(:user) }
  let!(:user_for_rdv) { create(:user) }
  let!(:motif) { create(:motif, organisation: organisation) }
  let!(:lieu) { create(:lieu, organisation: organisation) }
  let!(:creneau) { build(:creneau, :respects_booking_delays, motif: motif, starts_at: DateTime.parse("2020-10-20 09h30")) }
  let!(:plage_ouverture) { create(:plage_ouverture, motifs: [motif], lieu: lieu, organisation: organisation) }
  let(:mock_geo_search) { instance_double(Users::GeoSearch) }

  let(:attributes) do
    {
      starts_at: creneau.starts_at,
      motif_id: motif.id,
      lieu_id: lieu.id,
      user_ids: [user_for_rdv.id],
      departement: "62",
      city_code: "62100"
    }
  end
  let(:returned_creneau) { Creneau.new }

  before do
    expect(Users::GeoSearch).to receive(:new)
      .with(departement: "62", city_code: "62100")
      .and_return(mock_geo_search)
    expect(Users::CreneauSearch).to receive(:creneau_for).with(
      user: user,
      motif: motif,
      lieu: lieu,
      starts_at: DateTime.parse("2020-10-20 09h30"),
      geo_search: mock_geo_search
    ).and_return(returned_creneau)
  end

  describe "#new" do
    it "should work" do
      rdv_wizard = UserRdvWizard::Step1.new(user, attributes)
      expect(rdv_wizard.rdv.user_ids).to eq [user_for_rdv.id]
      expect(rdv_wizard.creneau).to eq returned_creneau
    end
  end
end
