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

  describe "#online_booking_only_proconnect?" do
    subject { organisation.online_booking_only_proconnect? }

    context "when other connexion types are allowed" do
      let(:organisation) { build(:organisation, online_booking_for_particuliers: true) }

      it { is_expected.to be false }
    end

    context "when only proconnect is allowed" do
      let(:organisation) do
        build(:organisation,
              online_booking_for_professionnels: true,
              online_booking_for_particuliers: false,
              online_booking_with_email: false)
      end

      it { is_expected.to be true }
    end
  end

  describe "after_update quand ants_connectable passe à true" do
    let!(:cni_category) { create(:motif_category, name: Api::Ants::EditorController::CNI_MOTIF_CATEGORY_NAME) }
    let!(:passport_category) { create(:motif_category, name: Api::Ants::EditorController::PASSPORT_MOTIF_CATEGORY_NAME) }
    let!(:cni_passport_category) { create(:motif_category, name: Api::Ants::EditorController::CNI_AND_PASSPORT_MOTIF_CATEGORY_NAME) }

    context "quand ants_connectable passe de false à true" do
      it "ajoute les catégories ANTS au territoire" do
        organisation = create(:organisation, ants_connectable: false)
        organisation.update!(ants_connectable: true)
        expect(organisation.territory.motif_categories).to contain_exactly(cni_category, passport_category, cni_passport_category)
      end
    end

    context "quand ants_connectable est déjà true à la création" do
      it "n'ajoute pas les catégories ANTS au territoire" do
        organisation = create(:organisation, ants_connectable: true)
        expect(organisation.territory.motif_categories).to be_empty
      end
    end

    context "quand un autre attribut change" do
      it "n'ajoute pas les catégories ANTS au territoire" do
        organisation = create(:organisation, ants_connectable: false)
        organisation.update!(name: "Nouveau nom")
        expect(organisation.territory.motif_categories).to be_empty
      end
    end
  end
end
