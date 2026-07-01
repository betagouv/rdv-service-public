RSpec.describe Users::RdvBookingForm do
  let(:domain) { Domain::RDV_SERVICE_PUBLIC }
  let!(:territory) { create(:territory) }
  let!(:organisation) { create(:organisation, territory:, name: "Mairie de Wavignies") }
  let!(:motif_category) { create(:motif_category, :passeport) }
  let!(:motif) { create(:motif, organisation:, motif_category:) }
  let!(:user) { create(:user) }
  let!(:lieu) { create(:lieu, organisation: organisation) }
  let!(:agent) { create(:agent, organisations: [organisation]) }
  let(:creneau) { build(:creneau, :respects_booking_delays, motif:, agent:, lieu_id: lieu.id) }
  let(:rdv_builder) { Users::RdvBuilder.new(user, { motif_id: motif.id, lieu_id: lieu.id, ants_pre_demandes_count: 1 }) }
  let(:user_attributes) { { first_name: "Léa", last_name: "Boubakar", phone_number: "0612345678", ants_pre_demande_number: } }

  include_context "rdv_mairie_api_authentication"

  before { allow(rdv_builder).to receive(:creneau).and_return(creneau) }

  context "numéro de pré-demande valide" do
    let(:ants_pre_demande_number) { "VALID12345" }

    before { stub_ants_status_ok("VALID12345", status: "validated", meeting_point_id: lieu.id, appointments: []) }

    it do
      form = described_class.new(user:, rdv_builder:, user_attributes:, domain:)
      expect { form.save }.to change(Rdv, :count).by(1)
    end
  end

  context "numéro de pré-demande vide" do
    let(:ants_pre_demande_number) { "" }

    it "empêche la création" do
      form = described_class.new(user:, rdv_builder:, user_attributes:, domain:)
      expect { form.save }.not_to change(Rdv, :count)
      expect(form.errors.count).to eq(1)
      expect(form.errors.first.attribute).to eq(:ants_pre_demande_number)
      # le message affiché est en fait celui sur le user
      expect(form.errors.first.full_message).to eq("Numéro de pré-demande ANTS doit être renseigné")
    end
  end

  context "numéro de pré-demande ANTS non reconnu" do
    let(:ants_pre_demande_number) { "VALID12345" }

    before { stub_ants_status_ok("VALID12345", status: "unknown", meeting_point_id: lieu.id, appointments: []) }

    it "empêche la création" do
      form = described_class.new(user:, rdv_builder:, user_attributes:, domain:)
      expect { form.save }.not_to change(Rdv, :count)
      expect(form.errors.count).to eq(1)
      expect(form.errors.first.attribute).to eq(:ants_pre_demande_number)
      expect(form.errors.first.full_message).to eq("Numéro de pré-demande ANTS n'est pas reconnu par l'ANTS")
    end
  end

  context "numéro de pré-demande ANTS qui a déjà un appointment" do
    let(:ants_pre_demande_number) { "VALID12345" }

    before do
      stub_ants_status_ok(
        "VALID12345",
        status: "validated",
        meeting_point_id: lieu.id,
        appointments: [{ "meeting_point" => "Mairie de Montrouge", "management_url" => "http://rdvsympa.fr/123" }]
      )
    end

    it "empêche la création" do
      form = described_class.new(user:, rdv_builder:, user_attributes:, domain:)
      expect { form.save }.not_to change(Rdv, :count)
      expect(form.errors.count).to eq(1)
      expect(form.errors.first.attribute).to eq(:_benign)
      expect(form.errors.first.message).to eq(
        <<-TXT.squish
              Ce numéro de pré-demande ANTS est déjà utilisé pour un RDV auprès de Mairie de Montrouge.
              Veuillez <a href="http://rdvsympa.fr/123" target="_blank">annuler ce RDV</a> avant d'en prendre un nouveau.
        TXT
      )
    end
  end

  context "numéro de pré-demande ANTS qui a déjà un appointment mais ignore les avertissements" do
    let(:ants_pre_demande_number) { "VALID12345" }
    let(:user_attributes) { super().merge(ignore_benign_errors: "true") }

    before do
      stub_ants_status_ok(
        "VALID12345",
        status: "validated",
        meeting_point_id: lieu.id,
        appointments: [{ "meeting_point" => "Mairie de Montrouge", "management_url" => "http://rdvsympa.fr/123" }]
      )
    end

    it "n'empêche pas la création" do
      form = described_class.new(user:, rdv_builder:, user_attributes:, domain:)
      expect { form.save }.to change(Rdv, :count).by(1)
    end
  end

  context "numéro de pré-demande ANTS valide mais l'API ANTS timeout" do
    let(:ants_pre_demande_number) { "VALID12345" }

    before { allow(AntsApi).to receive(:status).and_raise(Typhoeus::Errors::TimeoutError) }

    it "empêche la création" do
      form = described_class.new(user:, rdv_builder:, user_attributes:, domain:)
      expect { form.save }.not_to change(Rdv, :count)
      expect(form.errors.count).to eq(1)
      expect(form.errors.first.attribute).to eq(:ants_pre_demande_number)
      expect(form.errors.first.full_message).to eq("Numéro de pré-demande ANTS n'a pas pu être validé à cause d'une erreur inattendue. Merci de réessayer dans 30 secondes.")
    end
  end
end
