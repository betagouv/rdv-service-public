RSpec.describe Organisation, type: :model do
  describe ".contactable" do
    it "return nothing when no organisation" do
      expect(described_class.contactable).to be_empty
    end

    it "return organisation with phone number" do
      organisation = create(:organisation, phone_number: "01 02 03 04 05")
      create(:organisation, phone_number: nil)
      expect(described_class.contactable).to eq([organisation])
    end

    it "return organisation with a website" do
      organisation = create(:organisation, phone_number: nil, website: "https://pasdecalais.fr")
      create(:organisation, phone_number: nil, website: nil)
      expect(described_class.contactable).to eq([organisation])
    end

    it "return organisation with an email" do
      organisation = create(:organisation, phone_number: nil, website: nil, email: "aude@pasdecalais.fr")
      create(:organisation, phone_number: nil, website: nil, email: nil)
      expect(described_class.contactable).to eq([organisation])
    end
  end

  describe "#slug" do
    it "separates with dashes, squishes whitespace and skips special characters" do
      organisation = build(:organisation, name: "SDSEI Est Béarn - site de NAY ($`'&@*!:)")
      expect(organisation.slug).to eq("sdsei-est-bearn-site-de-nay")
    end

    it "limits length to 80" do
      organisation = build(:organisation, name: "SDSEI Pays Basque Intérieur - site de SAINT JEAN LE VIEUX mais aussi d'un autre endroit")
      expect(organisation.slug).to eq("sdsei-pays-basque-interieur-site-de-saint-jean-le-vieux-mais-aussi-d-un-autre-end")
    end
  end

  describe "phone_number" do
    it "invalid phone" do
      organisation = build(:organisation, phone_number: "12345")
      expect(organisation).to be_invalid
    end

    it "blank phone is valid" do
      organisation = build(:organisation, phone_number: nil)
      expect(organisation).to be_valid
    end

    it "4 digits phones are valid" do
      organisation = build(:organisation, phone_number: "3949")
      expect(organisation).to be_valid
    end
  end

  describe "#online_booking_only_sso?" do
    subject { organisation.online_booking_only_sso? }

    let(:territory) { build(:territory, id: territory_id) }
    let(:organisation) { create(:organisation, territory:, verticale:) }
    let(:motif) { create(:motif, organisation:) }

    context "when on RDV_SERVICE_PUBLIC domain with territory_id 2" do
      let(:territory_id) { 2 }
      let(:verticale) { :rdv_mairie }

      it { is_expected.to be true }
    end

    context "when on RDV_SERVICE_PUBLIC domain with a different territory_id" do
      let(:territory_id) { 123 }
      let(:verticale) { :rdv_mairie }

      it { is_expected.to be false }
    end

    context "when on RDV_SOLIDARITES domain with territory_id 2" do
      let(:territory_id) { 2 }
      let(:verticale) { :rdv_solidarites }

      it { is_expected.to be false }
    end
  end
end
