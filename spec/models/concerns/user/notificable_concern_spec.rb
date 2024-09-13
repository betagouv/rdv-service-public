RSpec.describe User::NotificableConcern do
  describe "#notifiable_by_email?" do
    subject { user.notifiable_by_email? }

    context "user has email and email notifications enabled" do
      let(:user) { build(:user, notification_email: "jean@lol.fr", notify_by_email: true) }

      it { is_expected.to be_truthy }
    end

    context "user has email but email notifications disabled" do
      let(:user) { build(:user, notification_email: "jean@lol.fr", notify_by_email: false) }

      it { is_expected.to be_falsy }
    end

    context "user has no email but email notifications enabled" do
      let(:user) { build(:user, notification_email: nil, notify_by_email: true) }

      it { is_expected.to be_falsy }
    end

    context "user has blank email but email notifications enabled" do
      let(:user) { build(:user, notification_email: "", notify_by_email: true) }

      it { is_expected.to be_falsy }
    end
  end

  describe "#notifiable_by_sms?" do
    subject { user.notifiable_by_sms? }

    context "user has phone number and SMS notifications enabled" do
      let(:user) { build(:user, phone_number: "0634343434", notify_by_sms: true) }

      it { is_expected.to be_truthy }
    end

    context "user has phone number but SMS notifications disabled" do
      let(:user) { build(:user, phone_number: "0634343434", notify_by_sms: false) }

      it { is_expected.to be_falsy }
    end

    context "user has SMS notifications enabled but no phone number" do
      let(:user) { build(:user, phone_number: nil, notify_by_sms: true) }

      it { is_expected.to be_falsy }
    end

    context "user has SMS notifications enabled but blank phone number" do
      let(:user) { build(:user, phone_number: "", notify_by_sms: true) }

      it { is_expected.to be_falsy }
    end

    context "user has SMS notifications enabled but landline phone number" do
      let(:user) { build(:user, phone_number: "0129292929", notify_by_sms: true) }

      it { is_expected.to be_falsy }
    end
  end
end
