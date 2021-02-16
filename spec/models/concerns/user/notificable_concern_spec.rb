describe User::NotificableConcern do
  describe "#notifiable_by_email?" do
    subject { user.notifiable_by_email? }

    context "user has email and email notifications enabled" do
      let(:user) { build(:user, email: "jean@lol.fr", notify_by_email: true) }
      it { should be_truthy }
    end

    context "user has email but email notifications disabled" do
      let(:user) { build(:user, email: "jean@lol.fr", notify_by_email: false) }
      it { should be_falsy }
    end

    context "user has no email but email notifications enabled" do
      let(:user) { build(:user, email: nil, notify_by_email: true) }
      it { should be_falsy }
    end

    context "user has blank email but email notifications enabled" do
      let(:user) { build(:user, email: "", notify_by_email: true) }
      it { should be_falsy }
    end
  end

  describe "#notifiable_by_sms?" do
    subject { user.notifiable_by_sms? }

    context "user has phone number and SMS notifications enabled" do
      let(:user) { build(:user, phone_number_formatted: "+33634343434", notify_by_sms: true) }
      it { should be_truthy }
    end

    context "user has phone number but SMS notifications disabled" do
      let(:user) { build(:user, phone_number_formatted: "+33634343434", notify_by_sms: false) }
      it { should be_falsy }
    end

    context "user has SMS notifications enabled but no phone number" do
      let(:user) { build(:user, phone_number_formatted: nil, notify_by_sms: true) }
      it { should be_falsy }
    end

    context "user has SMS notifications enabled but blank phone number" do
      let(:user) { build(:user, phone_number_formatted: "", notify_by_sms: true) }
      it { should be_falsy }
    end

    context "user has SMS notifications enabled but landline phone number" do
      let(:user) { build(:user, phone_number_formatted: "+33129292929", notify_by_sms: true) }
      it { should be_falsy }
    end
  end
end
