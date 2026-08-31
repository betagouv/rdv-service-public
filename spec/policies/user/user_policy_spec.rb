RSpec.describe User::UserPolicy do
  let(:pundit_user) { create(:user) }

  describe "#edit?" do
    subject { described_class.new(pundit_user, record_user).edit? }

    context "for the same user" do
      let(:record_user) { User.find(pundit_user.id) }

      it { is_expected.to be_truthy }

      context "when the user is not fully logged in" do
        before do
          pundit_user.signed_in_with_restricted_auth_token!
        end

        it { is_expected.to be_falsey }
      end
    end

    context "for an unrelated user" do
      let(:record_user) { create(:user) }

      it { is_expected.to be_falsey }
    end

    context "for a proche of the user" do
      let(:record_user) { create(:user, responsible: pundit_user) }

      it { is_expected.to be_truthy }
    end
  end
end
