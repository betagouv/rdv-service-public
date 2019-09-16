describe Rdv, type: :model do
  let(:motif) { create(:motif) }
  let(:motif_with_rdv) { create(:motif, :with_rdvs) }

  describe '#soft_delete' do
    before do
      freeze_time
      @delation_time = Time.current
      motif.soft_delete
      motif_with_rdv.soft_delete
    end

    it "doesn't delete the motif with rdvs" do
      expect(Motif.all).to eq [motif_with_rdv]
      expect(motif_with_rdv.reload.deleted_at).to eq @delation_time
    end
  end
end
