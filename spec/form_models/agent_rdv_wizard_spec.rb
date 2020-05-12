describe AgentRdvWizard do
  let(:organisation) { build(:organisation) }
  let!(:agent) { create(:agent) }
  let!(:user) { create(:user) }
  let(:rdv_attributes) { { user_ids: [user.id], notes: 'test' } }

  describe "#new" do
    it "should work" do
      rdv_wizard = AgentRdvWizard::Step1.new(agent, organisation, rdv_attributes)
      expect(rdv_wizard.rdv.user_ids).to eq [user.id]
      expect(rdv_wizard.agents.to_a).to eq [agent]
      expect(rdv_wizard.notes).to eq 'test'
    end

    describe "motif default behaviour" do
      context "linked to a motif" do
        let!(:motif) { create(:motif, default_duration_in_min: 25) }
        let(:rdv_attributes) { { user_ids: [user.id], motif_id: motif.id, notes: 'test' } }

        context "no duration passed explicitly" do
          it "should use motif default duration" do
            rdv_wizard = AgentRdvWizard::Step1.new(agent, organisation, rdv_attributes)
            expect(rdv_wizard.duration_in_min).to eq 25
          end
        end
        context "some duration passed explicitly" do
          it "should not use motif default duration" do
            rdv_wizard = AgentRdvWizard::Step1.new(agent, organisation, rdv_attributes.merge(duration_in_min: 7))
            expect(rdv_wizard.duration_in_min).to eq 7
          end
        end
      end

      describe "location default behaviour" do
        let(:rdv_attributes) { { user_ids: [user.id], motif_id: motif.id } }
        subject { AgentRdvWizard::Step1.new(agent, organisation, rdv_attributes).location }
        context "motif is public office" do
          let!(:motif) { create(:motif, :at_public_office) }
          let!(:user) { create(:user, address: "10 rue du havre") }
          it { should be_blank }
        end
        context "motif is at home and user has address" do
          let!(:motif) { create(:motif, :at_home) }
          let!(:user) { create(:user, address: "10 rue du havre") }
          it { should eq("10 rue du havre") }

          context "a different address is given in the wizard" do
            let(:rdv_attributes) { { user_ids: [user.id], motif_id: motif.id, location: "20 rue des PTT" } }

            it { should eq("20 rue des PTT") }
          end
        end
        context "motif is at home but user doesn't have an address" do
          let!(:motif) { create(:motif, :at_home) }
          let!(:user) { create(:user, address: "") }
          it { should be_blank }
        end
        context "motif is at home but user is a relative" do
          let!(:motif) { create(:motif, :at_home) }
          let!(:user_responsible) { create(:user, address: "10 rue du havre") }
          let!(:user) { create(:user, responsible: user_responsible, address: "") }
          it { should eq("10 rue du havre") }
        end
      end
    end
  end
end
