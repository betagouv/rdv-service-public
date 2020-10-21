describe UserRdvWizard do
  let!(:organisation) { create(:organisation) }
  let!(:user) { create(:user) }
  let!(:user_for_rdv) { create(:user) }
  let!(:motif) { create(:motif, organisation: organisation) }
  let!(:lieu) { create(:lieu, organisation: organisation) }
  let!(:creneau) { build(:creneau, :respects_booking_delays, motif: motif, starts_at: DateTime.parse("2020-10-20 09h30")) }
  let!(:plage_ouverture) { create(:plage_ouverture, motifs: [motif], lieu: lieu, organisation: organisation) }

  let(:rdv_attributes) do
    {
      starts_at: creneau.starts_at,
      motif_id: motif.id,
      lieu_id: lieu.id,
      user_ids: [user_for_rdv.id],
    }
  end
  let(:returned_creneau) { Creneau.new }

  before do
    expect(Users::CreneauSearch).to receive(:creneau_for).with(
      user: user,
      motif: motif,
      lieu: lieu,
      starts_at: DateTime.parse("2020-10-20 09h30")
    ).and_return(returned_creneau)
  end

  describe "#new" do
    it "should work" do
      rdv_wizard = UserRdvWizard::Step1.new(user, rdv_attributes)
      expect(rdv_wizard.rdv.user_ids).to eq [user_for_rdv.id]
      expect(rdv_wizard.creneau).to eq returned_creneau
    end
  end
end
