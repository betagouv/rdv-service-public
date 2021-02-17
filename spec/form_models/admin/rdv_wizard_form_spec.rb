describe Admin::RdvWizardForm do
  let(:organisation) { build(:organisation) }
  let!(:agent) { create(:agent) }
  let!(:user) { create(:user) }
  let(:rdv_attributes) { { user_ids: [user.id] } }

  describe "#new" do
    it "should work" do
      rdv_wizard = Admin::RdvWizardForm::Step1.new(agent, organisation, rdv_attributes)
      expect(rdv_wizard.rdv.user_ids).to eq [user.id]
      expect(rdv_wizard.agents.to_a).to eq [agent]
    end

    describe "motif default behaviour" do
      context "linked to a motif" do
        let!(:motif) { create(:motif, default_duration_in_min: 25) }
        let(:rdv_attributes) { { user_ids: [user.id], motif_id: motif.id } }

        context "no duration passed explicitly" do
          it "should use motif default duration" do
            rdv_wizard = Admin::RdvWizardForm::Step1.new(agent, organisation, rdv_attributes)
            expect(rdv_wizard.duration_in_min).to eq 25
          end
        end
        context "some duration passed explicitly" do
          it "should not use motif default duration" do
            rdv_wizard = Admin::RdvWizardForm::Step1.new(agent, organisation, rdv_attributes.merge(duration_in_min: 7))
            expect(rdv_wizard.duration_in_min).to eq 7
          end
        end
      end

      describe "rdv address default behaviour" do
        let(:lieu) { create(:lieu) }
        let(:rdv_attributes) { { user_ids: [user.id], motif_id: motif.id, lieu: lieu } }
        subject { Admin::RdvWizardForm::Step1.new(agent, organisation, rdv_attributes).rdv.address }
        context "motif is public office" do
          let!(:motif) { create(:motif, :at_public_office) }
          let!(:user) { create(:user, address: "10 rue du havre") }
          it { should be lieu.address }
        end
        context "motif is at home and user has address" do
          let!(:motif) { create(:motif, :at_home) }
          let!(:user) { create(:user, address: "10 rue du havre") }
          it { should eq "10 rue du havre" }
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
          it { should eq "10 rue du havre" }
        end
      end
    end
  end

  describe "Step2#save" do
    it "return true when everything is ok" do
      motif = create(:motif, :at_public_office, organisation: organisation)
      attributes = {
        starts_at: Time.zone.now,
        motif_id: motif.id,
        user_ids: [user.id],
      }
      rdv_wizard = Admin::RdvWizardForm::Step2.new(agent, organisation, attributes)
      expect(rdv_wizard.save).to be true
    end

    it "return false without user" do
      motif = create(:motif, :at_public_office, organisation: organisation)
      attributes = {
        starts_at: Time.zone.now,
        motif_id: motif.id
      }
      rdv_wizard = Admin::RdvWizardForm::Step2.new(agent, organisation, attributes)
      expect(rdv_wizard.save).to be false
    end

    it "return false when motif by phone nil user" do
      motif = create(:motif, :by_phone, organisation: organisation)
      attributes = {
        starts_at: Time.zone.now,
        motif_id: motif.id,
        user_ids: []
      }
      rdv_wizard = Admin::RdvWizardForm::Step2.new(agent, organisation, attributes)
      expect(rdv_wizard.save).to be false
    end

    it "return false when motif by phone and user phone is empty" do
      motif = create(:motif, :by_phone, organisation: organisation)
      user = create(:user, phone_number: nil, organisations: [organisation])
      attributes = {
        starts_at: Time.zone.now,
        motif_id: motif.id,
        user_ids: [user.id],
      }
      rdv_wizard = Admin::RdvWizardForm::Step2.new(agent, organisation, attributes)
      expect(rdv_wizard.save).to be false
    end

    it "return true when motif by phone and second user has phone number" do
      motif = create(:motif, :by_phone, organisation: organisation)
      user1 = create(:user, phone_number: nil, organisations: [organisation])
      user2 = create(:user, phone_number: "0649494949", organisations: [organisation])
      attributes = {
        starts_at: Time.zone.now,
        motif_id: motif.id,
        user_ids: [user1.id, user2.id],
      }
      rdv_wizard = Admin::RdvWizardForm::Step2.new(agent, organisation, attributes)
      expect(rdv_wizard.save).to be true
    end
  end
end
