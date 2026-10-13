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
      expect(organisation.errors.full_messages.to_sentence).to eq "Le numéro de téléphone est invalide. S'il s'agit d'un numéro étranger, saisissez l'indicatif du pays (ex : +32 pour la Belgique)."
    end

    it "blank phone is valid" do
      organisation = build(:organisation, phone_number: nil)
      expect(organisation).to be_valid
    end

    it "4 digits phones are valid" do
      organisation = build(:organisation, phone_number: "3949")
      expect(organisation).to be_valid
    end

    it "autorise les numéros de téléphone des DROM" do
      organisation = build(:organisation, phone_number: "0262 94 07 07")
      expect(organisation).to be_valid
    end

    it "autorise le numéro de téléphone de l'ambassade de France en Allemagne" do
      organisation = build(:organisation, phone_number: "+49(30)590039000")
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

  describe "#domain" do
    subject { organisation.domain }

    context "when the verticale is set to état" do
      let(:organisation) { build(:organisation, verticale: "rdv_etat") }

      it { is_expected.to eq(Domain::RDV_SERVICE_PUBLIC_ETAT) }
    end
  end

  describe "validation du site web" do
    it "accepte une URL https valide" do
      expect(build(:organisation, website: "https://www.pasdecalais.fr")).to be_valid
    end

    it "accepte une URL http" do
      expect(build(:organisation, website: "http://www.pasdecalais.fr")).to be_valid
    end

    it "accepte un site web vide" do
      expect(build(:organisation, website: nil)).to be_valid
    end

    it "refuse une URL sans protocole" do
      organisation = build(:organisation, website: "pasdecalais.fr")
      expect(organisation).to be_invalid
      expect(organisation.errors[:website]).to be_present
    end

    it "refuse un mail" do
      organisation = build(:organisation, website: "jeanne@pasdecalais.fr")
      expect(organisation).to be_invalid
      expect(organisation.errors[:website]).to be_present
    end

    it "ne bloque pas l'édition d'un autre attribut quand le site web invalide est inchangé" do
      organisation = create(:organisation)
      organisation.update_columns(website: "pasdecalais.fr") # rubocop:disable Rails/SkipsModelValidations

      organisation.name = "Nouveau nom"
      expect(organisation).to be_valid
    end
  end

  describe "#website_url" do
    it "renvoie le site web quand l'URL est valide" do
      organisation = build(:organisation, website: "https://www.pasdecalais.fr")
      expect(organisation.website_url).to eq("https://www.pasdecalais.fr")
    end

    it "renvoie nil quand l'URL est invalide" do
      organisation = build(:organisation, website: "mon site web")
      expect(organisation.website_url).to be_nil
    end

    it "renvoie nil quand le site web est vide" do
      organisation = build(:organisation, website: nil)
      expect(organisation.website_url).to be_nil
    end
  end
end
