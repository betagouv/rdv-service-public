RSpec.describe BeneficiaireForm do
  subject(:form) { described_class.new(params) }

  context "when all params are provided and valid" do
    let(:params) do
      {
        first_name: "Steve",
        last_name: "Rogne",
        phone_number: "0611223344",
      }
    end

    it { is_expected.to be_valid }
  end

  context "when first name is missing" do
    let(:params) do
      {
        first_name: "",
        last_name: "Rogne",
        phone_number: "0611223344",
      }
    end

    it do
      expect(form).to be_invalid
      expect(form.errors.first.full_message).to eq("Prénom doit être rempli(e)")
    end
  end

  context "when last name is missing" do
    let(:params) do
      {
        first_name: "Steve",
        last_name: "",
        phone_number: "0611223344",
      }
    end

    it do
      expect(form).to be_invalid
      expect(form.errors.first.full_message).to eq("Nom d’usage doit être rempli(e)")
    end
  end

  context "when phone number is missing" do
    let(:params) do
      {
        first_name: "Steve",
        last_name: "Rogne",
        phone_number: "",
      }
    end

    it do
      expect(form).to be_invalid
      expect(form.benign_errors.first).to eq("Sans numéro de téléphone, aucune notification ne sera envoyée au bénéficiaire")
    end
  end

  context "when phone number is invalid" do
    let(:params) do
      {
        first_name: "Steve",
        last_name: "Rogne",
        phone_number: "1234",
      }
    end

    it do
      expect(form).to be_invalid
      expect(form.errors.first.full_message).to eq("Téléphone n'est pas valide")
    end
  end

  context "when phone number is not mobile" do
    let(:params) do
      {
        first_name: "Steve",
        last_name: "Rogne",
        phone_number: "0123456789",
      }
    end

    specify do
      expect(form).to be_invalid
      expect(form.errors.first.full_message).to eq("Téléphone ne permet pas de recevoir des SMS")
    end
  end

  context "pour un motif demandant un numéro de pré-demande ANTS" do
    include_context "rdv_mairie_api_authentication"
    let!(:territory) { create(:territory, :mairies) }
    let!(:organisation) { create(:organisation, territory:, name: "Mairie de Wavignies") }
    let!(:motif_category) { create(:motif_category, :passeport) }
    let!(:motif) { create(:motif, organisation:, motif_category:) }
    let(:params) do
      {
        motif_id: motif.id,
        first_name: "Steve",
        last_name: "Rogne",
        phone_number: "0611223344",
        ants_pre_demande_number:,
      }
    end

    context "numéro de pré-demande ANTS vide" do
      let(:ants_pre_demande_number) { "" }

      specify do
        expect(form).to be_invalid
        expect(form.errors.first.full_message).to eq("Numéro de pré-demande ANTS doit comporter 10 chiffres et lettres")
      end
    end

    context "numéro de pré-demande ANTS mal formatté" do
      let(:ants_pre_demande_number) { "ACSoup" }

      specify do
        expect(form).to be_invalid
        expect(form.errors.first.full_message).to eq("Numéro de pré-demande ANTS doit comporter 10 chiffres et lettres")
      end
    end

    context "numéro de pré-demande ANTS valide" do
      before { stub_ants_status_ok("VALID12345", status: "validated", appointments: []) }

      let(:ants_pre_demande_number) { "VALID12345" }

      specify do
        expect(form).to be_valid
      end
    end

    context "numéro de pré-demande ANTS non-reconnu (status unknown)" do
      before { stub_ants_status_ok("VALID12345", status: "unknown", appointments: []) }

      let(:ants_pre_demande_number) { "VALID12345" }

      specify do
        expect(form).to be_invalid
        expect(form.errors.first.full_message).to eq("Numéro de pré-demande ANTS n'est pas reconnu par l'ANTS")
      end
    end

    context "numéro de pré-demande ANTS a déjà un appointment" do
      before do
        stub_ants_status_ok(
          "VALID12345",
          status: "validated",
          appointments: [{ "meeting_point" => "Mairie de Montrouge", "management_url" => "http://rdvsympa.fr/123" }]
        )
      end

      let(:ants_pre_demande_number) { "VALID12345" }

      specify do
        expect(form).to be_invalid
        expect(form.errors.first.attribute).to eq(:_benign)
        expect(form.errors.first.message).to eq(
          <<-TXT.squish
            Ce numéro de pré-demande ANTS est déjà utilisé pour un RDV auprès de Mairie de Montrouge.
            Veuillez <a href="http://rdvsympa.fr/123" target="_blank">annuler ce RDV<a> avant d'en prendre un nouveau.
          TXT
        )
      end
    end

    context "numéro de pré-demande ANTS a déjà un appointment mais les avertissements sont ignorés" do
      before do
        stub_ants_status_ok(
          "VALID12345",
          status: "validated",
          appointments: [{ "meeting_point" => "Mairie de Montrouge", "management_url" => "http://rdvsympa.fr/123" }]
        )
      end

      let(:params) do
        {
          motif_id: motif.id,
          first_name: "Steve",
          last_name: "Rogne",
          phone_number: "0611223344",
          ants_pre_demande_number: "VALID12345",
          ignore_benign_errors: "true",
        }
      end

      specify do
        expect(form).to be_valid
      end
    end

    context "l’API ANTS timeoute" do
      before { allow(AntsApi).to receive(:status).and_raise(Typhoeus::Errors::TimeoutError) }

      let(:ants_pre_demande_number) { "VALID12345" }

      specify do
        expect(form).to be_invalid
        expect(form.errors.first.full_message).to eq("Numéro de pré-demande ANTS n'a pas pu être validé à cause d'une erreur inattendue. Merci de réessayer dans 30 secondes.")
      end
    end
  end
end
