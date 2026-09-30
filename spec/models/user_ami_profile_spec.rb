RSpec.describe UserAmiProfile do
  before do
    allow(Ami).to receive(:enabled?).and_return(true)
  end

  describe ".show_checkbox_in_user_form?" do
    subject { described_class.show_checkbox_in_user_form?(user, unconfirmed_rdv) }

    let(:user) { create(:user, organisations: [organisation]) }
    let!(:user_ami_profile) { create(:user_ami_profile, user:) }

    context "when using the plain user form" do
      let(:unconfirmed_rdv) { nil }

      context "when the user is linked to an organisation using AMI" do
        let(:organisation) { create(:organisation, ami_enabled: true) }

        it { is_expected.to be_truthy }
      end

      context "when the user isn't linked to any organisation using AMI" do
        let(:organisation) { create(:organisation, ami_enabled: false) }

        it { is_expected.to be_falsey }
      end
    end

    context "when confirming a rdv" do
      let(:unconfirmed_rdv) { build(:rdv, organisation:) }

      context "when the rdv is linked to an organisation using AMI" do
        let(:organisation) { create(:organisation, ami_enabled: true) }

        it { is_expected.to be_truthy }

        context "when the user doesn't have a UserAmiProfile because they didn't use FranceConnect" do
          let!(:user_ami_profile) { nil }

          it { is_expected.to be_falsey }
        end
      end

      context "when the rdv is not linked to an organisation using AMI" do
        let(:organisation) { create(:organisation, ami_enabled: false) }

        it { is_expected.to be_falsey }
      end
    end
  end
end
