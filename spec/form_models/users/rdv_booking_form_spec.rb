RSpec.describe Users::RdvBookingForm, type: :form_model do
  subject(:form) { described_class.new(user:, rdv_wizard:, domain:) }

  let(:territory) { create(:territory) }
  let(:organisation) { create(:organisation, territory:) }
  let(:motif) { create(:motif, organisation:) }
  let(:lieu) { create(:lieu, organisation:) }
  let(:user) { create(:user) }
  let(:domain) { Domain::RDV_SOLIDARITES }
  let(:rdv_wizard) { UserRdvWizard::Step1.new(user, { motif_id: motif.id, lieu_id: lieu.id }) }

  before { create(:user_profile, user:, organisation:) }

  describe "#show_birth_date_field?" do
    it "retourne false quand le territoire ne l'active pas" do
      expect(form.show_birth_date_field?).to be(false)
    end

    context "territoire avec champ date de naissance activé" do
      let(:territory) { create(:territory, enable_birth_date_field: true) }

      it "retourne true" do
        expect(form.show_birth_date_field?).to be(true)
      end
    end
  end

  describe "#show_ants_pre_demande_number_field?" do
    it "retourne false pour un motif standard" do
      expect(form.show_ants_pre_demande_number_field?).to be(false)
    end

    context "motif CNI/passeport nécessitant numéro ANTS" do
      let(:motif_category) { create(:motif_category, name: Api::Ants::EditorController::CNI_MOTIF_CATEGORY_NAME) }
      let(:motif) { create(:motif, organisation:, motif_category:) }

      it "retourne true" do
        expect(form.show_ants_pre_demande_number_field?).to be(true)
      end
    end
  end

  describe "#phone_required?" do
    it "retourne false pour un motif sur place" do
      expect(form.phone_required?).to be(false)
    end

    context "motif téléphonique" do
      let(:motif) { create(:motif, :by_phone, organisation:) }

      it "retourne true" do
        expect(form.phone_required?).to be(true)
      end
    end
  end

  describe "#show_address_field?" do
    it "retourne false quand le territoire ne l'active pas" do
      expect(form.show_address_field?).to be(false)
    end

    context "territoire avec champ adresse activé" do
      let(:territory) { create(:territory, enable_address_field: true) }

      it "retourne true" do
        expect(form.show_address_field?).to be(true)
      end
    end
  end

  describe "#address_required?" do
    it "retourne false pour un motif sur place" do
      expect(form.address_required?).to be(false)
    end

    context "motif à domicile" do
      let(:motif) { create(:motif, :at_home, organisation:) }

      it "retourne true" do
        expect(form.address_required?).to be(true)
      end
    end
  end

  describe "#show_logement_field?" do
    it "retourne false quand le territoire ne l'active pas" do
      expect(form.show_logement_field?).to be(false)
    end

    context "territoire avec champ logement activé" do
      let(:territory) { create(:territory, enable_logement_field: true) }

      it "retourne true" do
        expect(form.show_logement_field?).to be(true)
      end
    end
  end
end
