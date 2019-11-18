describe Rdv, type: :model do
  describe "#associate_users_with_organisation" do
    let(:organisation) { create(:organisation) }
    let(:organisation2) { create(:organisation) }
    let(:user) { create(:user, organisations: [organisation]) }
    let!(:rdv) { build(:rdv, users: [user], organisation: organisation2) }

    subject do
      rdv.save
      user.reload
    end

    it "expect .save to trigger #associate_users_with_organisation" do
      expect(rdv).to receive(:associate_users_with_organisation)
      subject
    end

    it "expect .save link user to organisation" do
      expect { subject }.to change { user.organisation_ids.sort }.from([organisation.id]).to([organisation.id, rdv.organisation_id].sort)
    end

    describe "when user is already associated to organisation" do
      let(:user) { create(:user, organisations: [organisation, organisation2]) }

      it "does not change anything" do
        expect { subject }.not_to raise_error
        expect { subject }.not_to change(user, :organisation_ids)
      end
    end
  end
end
