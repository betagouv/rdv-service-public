describe UserRdvWizard do
  let!(:user) { create(:user) }
  let!(:user_for_rdv) { create(:user) }
  let!(:motif) { create(:motif) }
  let!(:creneau) { build(:creneau, :respects_booking_delays, motif: motif) }
  let!(:plage_ouverture) { create(:plage_ouverture, motifs: [motif]) }

  let(:rdv_attributes) do
    {
      starts_at: creneau.starts_at,
      motif_id: motif.id,
      lieu_id: plage_ouverture.lieu.id,
      user_ids: [user_for_rdv.id],
    }
  end

  describe "#new" do
    it "should work" do
      rdv_wizard = UserRdvWizard::Step1.new(user, rdv_attributes)
      expect(rdv_wizard.rdv.user_ids).to eq [user_for_rdv.id]
      expect(rdv_wizard.creneau.starts_at).to eq creneau.starts_at
      expect(rdv_wizard.creneau.motif).to eq motif
    end
  end
end
