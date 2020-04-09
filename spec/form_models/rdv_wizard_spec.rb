describe RdvWizard do
  let(:organisation) { build(:organisation) }
  let!(:agent) { create(:agent) }
  let!(:user) { create(:user) }
  let(:rdv_attributes) { { user_ids: [user.id], notes: 'test' } }

  describe "#new" do
    it "should work" do
      rdv_wizard = RdvWizard::Step1.new(agent, organisation, rdv_attributes)
      expect(rdv_wizard.rdv.user_ids).to eq [user.id]
      expect(rdv_wizard.agents.to_a).to eq [agent]
      expect(rdv_wizard.notes).to eq 'test'
    end

    context "linked to a motif" do
      let!(:motif) { create(:motif, default_duration_in_min: 25) }
      let(:rdv_attributes) { { user_ids: [user.id], motif_id: motif.id, notes: 'test' } }

      context "no duration passed explicitly" do
        it "should use motif default duration" do
          rdv_wizard = RdvWizard::Step1.new(agent, organisation, rdv_attributes)
          expect(rdv_wizard.duration_in_min).to eq 25
        end
      end
      context "some duration passed explicitly" do
        it "should not use motif default duration" do
          rdv_wizard = RdvWizard::Step1.new(agent, organisation, rdv_attributes.merge(duration_in_min: 7))
          expect(rdv_wizard.duration_in_min).to eq 7
        end
      end
    end
  end
end
