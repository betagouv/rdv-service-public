RSpec.describe Admin::RdvWizardForm::Step1 do
  let(:organisation) { build(:organisation) }
  let!(:agent) { create(:agent) }
  let!(:user) { create(:user) }
  let(:rdv_attributes) { { user_ids: [user.id] } }

  describe "#new" do
    it "works" do
      rdv_wizard = described_class.new(agent, organisation, rdv_attributes)
      expect(rdv_wizard.rdv.user_ids).to eq [user.id]
      expect(rdv_wizard.agents.to_a).to eq [agent]
    end

    describe "motif default behaviour" do
      context "linked to a motif" do
        let!(:motif) { create(:motif, default_duration_in_min: 25) }
        let(:rdv_attributes) { { user_ids: [user.id], motif_id: motif.id } }

        context "no duration passed explicitly" do
          it "uses motif default duration" do
            rdv_wizard = described_class.new(agent, organisation, rdv_attributes)
            expect(rdv_wizard.duration_in_min).to eq 25
          end
        end

        context "some duration passed explicitly" do
          it "does not use motif default duration" do
            rdv_wizard = described_class.new(agent, organisation, rdv_attributes.merge(duration_in_min: 7))
            expect(rdv_wizard.duration_in_min).to eq 7
          end
        end
      end

      describe "rdv address default behaviour" do
        subject { described_class.new(agent, organisation, rdv_attributes).rdv.address }

        let(:lieu) { create(:lieu) }
        let(:rdv_attributes) { { user_ids: [user.id], motif_id: motif.id, lieu: lieu } }

        context "motif is public office" do
          let!(:motif) { create(:motif, :at_public_office) }
          let!(:user) { create(:user, address: "10 rue du havre, Paris, 75009") }

          it { is_expected.to be lieu.address }
        end

        context "motif is at home and user has address" do
          let!(:motif) { create(:motif, :at_home) }
          let!(:user) { create(:user, address: "10 rue du havre, Paris, 75009") }

          it { is_expected.to eq "10 rue du havre, Paris, 75009" }
        end

        context "motif is at home but user doesn't have an address" do
          let!(:motif) { create(:motif, :at_home) }
          let!(:user) { create(:user, address: "") }

          it { is_expected.to be_blank }
        end

        context "motif is at home but user is a relative" do
          let!(:motif) { create(:motif, :at_home) }
          let!(:user_responsible) { create(:user, address: "10 rue du havre, Paris, 75009") }
          let!(:user) { create(:user, responsible: user_responsible, address: "") }

          it { is_expected.to eq "10 rue du havre, Paris, 75009" }
        end
      end
    end
  end
end
