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

  describe "#cancel" do
    let(:rdv) { create(:rdv) }
    let(:now) { Time.current }

    subject { rdv.cancel }

    before { freeze_time }
    after { travel_back }

    it "should set cancelled_at" do
      expect { subject }.to change { rdv.cancelled_at }.from(nil).to(now)
    end
  end

  describe "#send_notifications_to_users" do
    let(:rdv) { build(:rdv) }

    it "should be called after create" do
      expect(rdv).to receive(:send_notifications_to_users)
      rdv.save!
    end

    context "when rdv already exist" do
      let(:rdv) { create(:rdv) }

      it "should not be called" do
        expect(rdv).not_to receive(:send_notifications_to_users)
        rdv.save!
      end
    end

    it "calls RdvMailer to send email to user" do
      expect(RdvMailer).to receive(:send_ics_to_user).with(rdv, rdv.users.first).and_return(double(deliver_later: nil))
      rdv.save!
    end
  end
end
