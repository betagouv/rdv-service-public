describe Rdv, type: :model do
  it "a une fabrique valide" do
    expect(build(:rdv)).to be_valid
  end

  describe "#notify_rdv_created" do
    let(:rdv) { build(:rdv, starts_at: 3.days.from_now) }

    it "should be called after create" do
      expect(rdv).to receive(:notify_rdv_created)
      rdv.save!
    end
  end

  describe "#notify_rdv_updated" do
    let(:rdv) { create(:rdv, starts_at: 3.days.from_now) }

    it "should be called after update starts_at" do
      expect(rdv).to receive(:notify_rdv_updated)
      rdv.update!(starts_at: 7.days.from_now)
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

  describe "#cancellable?" do
    let(:now) { Time.current }

    subject { rdv.cancellable? }

    before { travel_to(now) }
    after { travel_back }

    context "when Rdv starts in 5 hours" do
      let(:rdv) { create(:rdv, starts_at: 5.hours.from_now) }

      it { expect(subject).to eq(true) }

      context "but is already cancelled" do
        let(:rdv) { create(:rdv, cancelled_at: 1.hour.ago, starts_at: 5.hours.from_now) }

        it { expect(subject).to eq(false) }
      end
    end

    context "when Rdv starts in 4 hours" do
      let(:rdv) { create(:rdv, starts_at: 4.hours.from_now) }

      it { expect(subject).to eq(false) }
    end
  end

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

  describe "valid?" do
    let(:rdv) { build(:rdv, users: users) }
    let(:user_without_email) { create(:user, :with_no_email) }

    subject { rdv.save! }

    context "with a user with no email" do
      let(:users) { [User.find(user_without_email.id)] }

      it do
        rdv.save
        expect(rdv.valid?).to eq(true)
      end
    end
  end

end
