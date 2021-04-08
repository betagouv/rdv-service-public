describe Admin::RdvWizardForm::Step2 do
  let(:organisation) { build(:organisation) }
  let!(:agent) { create(:agent) }
  let!(:user) { create(:user) }
  let(:rdv_attributes) { { user_ids: [user.id] } }

  describe "#save" do
    it "return true when everything is ok" do
      motif = create(:motif, :at_public_office, organisation: organisation)
      attributes = {
        starts_at: Time.zone.now,
        motif_id: motif.id,
        user_ids: [user.id],
      }
      rdv_wizard = described_class.new(agent, organisation, attributes)
      expect(rdv_wizard.save).to be true
    end

    it "return false without user" do
      motif = create(:motif, :at_public_office, organisation: organisation)
      attributes = {
        starts_at: Time.zone.now,
        motif_id: motif.id
      }
      rdv_wizard = described_class.new(agent, organisation, attributes)
      expect(rdv_wizard.save).to be false
    end

    it "return false when motif by phone nil user" do
      motif = create(:motif, :by_phone, organisation: organisation)
      attributes = {
        starts_at: Time.zone.now,
        motif_id: motif.id,
        user_ids: []
      }
      rdv_wizard = described_class.new(agent, organisation, attributes)
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
      rdv_wizard = described_class.new(agent, organisation, attributes)
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
      rdv_wizard = described_class.new(agent, organisation, attributes)
      expect(rdv_wizard.save).to be true
    end
  end
end
