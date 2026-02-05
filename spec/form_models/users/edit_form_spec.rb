RSpec.describe Users::EditForm, type: :form_model do
  subject(:form) { described_class.new(user:, domain:) }

  let(:territory) { create(:territory) }
  let(:organisation) { create(:organisation, territory:) }
  let(:user) { create(:user) }
  let(:domain) { Domain::RDV_SOLIDARITES }

  before { create(:user_profile, user:, organisation:) }

  describe "#show_birth_name_field?" do
    it "retourne true pour un usager standard sur RDV Solidarités" do
      expect(form.show_birth_name_field?).to be(true)
    end

    context "sur le domaine RDV Service Public" do
      let(:domain) { Domain::RDV_SERVICE_PUBLIC }

      it "retourne false" do
        expect(form.show_birth_name_field?).to be(false)
      end
    end

    context "usager connecté via ProConnect" do
      let(:user) { create(:user, pro_connect_openid_sub: "abc123") }

      it "retourne false" do
        expect(form.show_birth_name_field?).to be(false)
      end
    end
  end

  describe "#first_name_frozen?" do
    it "retourne false pour un usager standard" do
      expect(form.first_name_frozen?).to be(false)
    end

    context "usager connecté via FranceConnect" do
      let(:user) { create(:user, franceconnect_openid_sub: "fc-123") }

      it "retourne true" do
        expect(form.first_name_frozen?).to be(true)
      end
    end
  end

  describe "#show_email_field?" do
    subject { form.show_email_field? }

    it { is_expected.to be_falsey }

    context "usager invité avec email" do
      before { user.signed_in_with_invitation_token! }

      it { is_expected.to be(true) }
    end
  end

  describe "#show_notification_email_field?" do
    subject { form.show_notification_email_field? }

    it { is_expected.to be_falsey }

    context "usager sans email, connecté via SSO avec notification_email" do
      let(:user) { create(:user, email: nil, notification_email: "notif@example.com", franceconnect_openid_sub: "fc-123") }

      it { is_expected.to be(true) }
    end
  end

  describe "#show_caisse_affiliation_field?" do
    it "retourne false quand le territoire ne l'active pas" do
      expect(form.show_caisse_affiliation_field?).to be(false)
    end

    context "territoire avec champ caisse_affiliation activé" do
      let(:territory) { create(:territory, enable_caisse_affiliation_field: true) }

      it "retourne true" do
        expect(form.show_caisse_affiliation_field?).to be(true)
      end
    end
  end
end
