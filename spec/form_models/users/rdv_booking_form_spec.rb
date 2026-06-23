RSpec.describe Users::RdvBookingForm do
  context "cas classique" do
    let(:domain) { Domain::RDV_SERVICE_PUBLIC }
    let!(:organisation) { create(:organisation) }
    let!(:motif) { create(:motif, :at_public_office, organisation:) }
    let!(:lieu) { create(:lieu, organisation:) }
    let!(:agent) { create(:agent, organisations: [organisation]) }
    let(:creneau) { build(:creneau, :respects_booking_delays, motif:, agent:, lieu_id: lieu.id) }
    let(:rdv_builder) { Users::RdvBuilder.new(user, { motif_id: motif.id, lieu_id: lieu.id }) }
    let!(:user) { create(:user) }
    let(:user_attributes) { { first_name: "Léa", last_name: "Boubakar", phone_number: nil } }

    before { allow(rdv_builder).to receive(:creneau).and_return(creneau) }

    it do
      form = described_class.new(user:, rdv_builder:, user_attributes:, domain:)
      expect { form.save }
        .to change(Rdv, :count).by(1)
        .and have_enqueued_mail(Users::RdvMailer, :rdv_created)
        .and have_enqueued_mail(Agents::RdvMailer, :rdv_created)
      rdv = form.rdv
      expect(rdv).to be_persisted
      expect(rdv.motif).to eq(motif)
      expect(rdv.lieu).to eq(lieu)
      expect(rdv.agents).to contain_exactly(agent)
      expect(rdv.users).to contain_exactly(user)
      expect(rdv.created_by).to eq(user)
      expect(user.reload.first_name).to eq("Léa")
      expect(user.reload.last_name).to eq("Boubakar")
      expect(form.invitation_token).to be_present
    end
  end

  context "pour un proche créé à la volée" do
    let(:domain) { Domain::RDV_SERVICE_PUBLIC }
    let!(:organisation) { create(:organisation) }
    let!(:motif) { create(:motif, :at_public_office, organisation:) }
    let!(:lieu) { create(:lieu, organisation:) }
    let!(:agent) { create(:agent, organisations: [organisation]) }
    let(:creneau) { build(:creneau, :respects_booking_delays, motif:, agent:, lieu_id: lieu.id) }
    let(:rdv_builder) { Users::RdvBuilder.new(user, { motif_id: motif.id, lieu_id: lieu.id }) }
    let!(:user) { create(:user) }
    let(:user_attributes) do
      {
        first_name: "Léa",
        last_name: "Boubakar",
        relatives_attributes: { "0" => { first_name: "Marc", last_name: "Durant" } },
      }
    end

    before { allow(rdv_builder).to receive(:creneau).and_return(creneau) }

    it do
      form = described_class.new(user:, rdv_builder:, user_attributes:, domain:, selected_proche: "new")
      expect { form.save }.to change(Rdv, :count).by(1).and change(User, :count).by(1)
      proche = user.reload.relatives.first
      expect(form.rdv.users).to contain_exactly(proche)
      expect(proche.first_name).to eq("Marc")
      expect(proche.created_through).to eq("user_relative_creation")
      expect(proche.organisation_ids).to contain_exactly(organisation.id)
    end
  end

  context "pour un proche créé à la volée mais le prénom n'est pas renseigné" do
    let(:domain) { Domain::RDV_SERVICE_PUBLIC }
    let!(:organisation) { create(:organisation) }
    let!(:motif) { create(:motif, :at_public_office, organisation:) }
    let!(:lieu) { create(:lieu, organisation:) }
    let!(:agent) { create(:agent, organisations: [organisation]) }
    let(:creneau) { build(:creneau, :respects_booking_delays, motif:, agent:, lieu_id: lieu.id) }
    let(:rdv_builder) { Users::RdvBuilder.new(user, { motif_id: motif.id, lieu_id: lieu.id }) }
    let!(:user) { create(:user) }
    let(:user_attributes) do
      {
        first_name: "Léa",
        last_name: "Boubakar",
        phone_number: nil,
        relatives_attributes: { "0" => { first_name: "", last_name: "Durant" } },
      }
    end

    it "empêche la création" do
      form = described_class.new(user:, rdv_builder:, user_attributes:, domain:, selected_proche: "new")
      expect { form.save }.not_to change(Rdv, :count)
      expect(user.reload.relatives).to be_empty
    end
  end

  context "pour un proche déjà existant" do
    let(:domain) { Domain::RDV_SERVICE_PUBLIC }
    let!(:organisation) { create(:organisation) }
    let!(:motif) { create(:motif, :at_public_office, organisation:) }
    let!(:lieu) { create(:lieu, organisation:) }
    let!(:agent) { create(:agent, organisations: [organisation]) }
    let(:creneau) { build(:creneau, :respects_booking_delays, motif:, agent:, lieu_id: lieu.id) }
    let(:rdv_builder) { Users::RdvBuilder.new(user, { motif_id: motif.id, lieu_id: lieu.id }) }
    let!(:user) { create(:user) }
    let!(:proche) { create(:user, :relative, responsible: user) }
    let(:user_attributes) { { first_name: "Léa", last_name: "Boubakar", phone_number: nil } }

    before { allow(rdv_builder).to receive(:creneau).and_return(creneau) }

    it do
      form = described_class.new(user:, rdv_builder:, user_attributes:, domain:, selected_proche: proche.id.to_s)
      expect { form.save }.to change(Rdv, :count).by(1)
      expect(form.rdv.users).to contain_exactly(proche)
      expect(proche.organisation_ids).to include(organisation.id)
    end
  end

  context "motif ANTS avec un proche créé à la volée" do
    let(:domain) { Domain::RDV_SERVICE_PUBLIC }
    let!(:territory) { create(:territory) }
    let!(:organisation) { create(:organisation, territory:, name: "Mairie de Wavignies") }
    let!(:motif_category) { create(:motif_category, :passeport) }
    let!(:motif) { create(:motif, organisation:, motif_category:) }
    let!(:user) { create(:user) }
    let!(:lieu) { create(:lieu, organisation:) }
    let!(:agent) { create(:agent, organisations: [organisation]) }
    let(:creneau) { build(:creneau, :respects_booking_delays, motif:, agent:, lieu_id: lieu.id) }
    let(:rdv_builder) { Users::RdvBuilder.new(user, { motif_id: motif.id, lieu_id: lieu.id, ants_pre_demandes_count: 2 }) }
    let(:user_attributes) do
      {
        first_name: "Léa",
        last_name: "Boubakar",
        phone_number: "0612345678",
        ants_pre_demande_number: "VALID12345",
        relatives_attributes: { "0" => { first_name: "Marc", last_name: "Durant", ants_pre_demande_number: "PROCHE6789" } },
      }
    end

    include_context "rdv_mairie_api_authentication"

    before do
      allow(rdv_builder).to receive(:creneau).and_return(creneau)
      stub_ants_status_ok("VALID12345", status: "validated", meeting_point_id: lieu.id, appointments: [])
      stub_ants_status_ok("PROCHE6789", status: "validated", meeting_point_id: lieu.id, appointments: [])
    end

    it "crée le RDV pour l'usager et le proche" do
      form = described_class.new(user:, rdv_builder:, user_attributes:, domain:)
      expect { form.save }.to change(Rdv, :count).by(1).and change(User, :count).by(1)
      proche = user.reload.relatives.first
      expect(form.rdv.users).to contain_exactly(user, proche)
      expect(proche.ants_pre_demande_number).to eq("PROCHE6789")
      expect(proche.created_through).to eq("user_relative_creation")
    end

    context "avec un numéro de proche manquant" do
      let(:user_attributes) do
        super().merge(
          relatives_attributes: { "0" => { first_name: "Marc", last_name: "Durant", ants_pre_demande_number: "" } }
        )
      end

      it "ne crée pas le RDV" do
        form = described_class.new(user:, rdv_builder:, user_attributes:, domain:)
        expect { form.save }.not_to change(Rdv, :count)
      end
    end

    context "avec un numéro de proche au mauvais format" do
      let(:user_attributes) do
        super().merge(
          relatives_attributes: { "0" => { first_name: "Marc", last_name: "Durant", ants_pre_demande_number: "TROP_COURT" } }
        )
      end

      it "ne crée pas le RDV" do
        form = described_class.new(user:, rdv_builder:, user_attributes:, domain:)
        expect { form.save }.not_to change(Rdv, :count)
      end
    end

    context "avec un numéro de proche au statut consommé" do
      let(:user_attributes) do
        super().merge(
          relatives_attributes: { "0" => { first_name: "Marc", last_name: "Durant", ants_pre_demande_number: "CONSOMME99" } }
        )
      end

      before { stub_ants_status_ok("CONSOMME99", status: "consumed", meeting_point_id: lieu.id, appointments: []) }

      it "ne crée pas le RDV" do
        form = described_class.new(user:, rdv_builder:, user_attributes:, domain:)
        expect { form.save }.not_to change(Rdv, :count)
      end
    end
  end

  context "motif téléphonique" do
    let(:domain) { Domain::RDV_SERVICE_PUBLIC }
    let!(:organisation) { create(:organisation) }
    let(:motif) { create(:motif, :by_phone, organisation: organisation) }
    let!(:lieu) { create(:lieu, organisation: organisation) }
    let!(:agent) { create(:agent, organisations: [organisation]) }
    let(:creneau) { build(:creneau, :respects_booking_delays, motif:, agent:, lieu_id: lieu.id) }
    let!(:user) { create(:user) }

    before { allow(rdv_builder).to receive(:creneau).and_return(creneau) }

    context "aucun lieu passé" do
      let(:rdv_builder) { Users::RdvBuilder.new(user, { motif_id: motif.id, lieu_id: nil }) }
      let(:user_attributes) { { first_name: "Léa", last_name: "Boubakar", phone_number: "0612345678" } }

      it do
        form = described_class.new(user:, rdv_builder:, user_attributes:, domain:)
        expect { form.save }.to change(Rdv, :count).by(1)
      end
    end

    context "numéro de téléphone invalide" do
      let(:rdv_builder) { Users::RdvBuilder.new(user, { motif_id: motif.id, lieu_id: lieu.id }) }
      let(:user_attributes) { { first_name: "Léa", last_name: "Boubakar", phone_number: "0633" } }

      it "affiche un message d'erreur complet incluant le nom du champ" do
        form = described_class.new(user:, rdv_builder:, user_attributes:, domain:)
        expect { form.save }.not_to change(Rdv, :count)
        expect(form.errors.full_messages).to include("Le numéro de téléphone est invalide. S'il s'agit d'un numéro étranger, saisissez l'indicatif du pays (ex : +32 pour la Belgique).")
      end
    end

    context "numéro de téléphone vide" do
      let(:rdv_builder) { Users::RdvBuilder.new(user, { motif_id: motif.id, lieu_id: lieu.id }) }
      let(:user_attributes) { { first_name: "Léa", last_name: "Boubakar", phone_number: nil } }

      it "échoue avec un message d'erreur explicite" do
        form = described_class.new(user:, rdv_builder:, user_attributes:, domain:)
        expect { form.save }.not_to change(Rdv, :count)
        expect(form.errors.full_messages.join(", ")).to eq("Le numéro de téléphone est obligatoire car le RDV aura lieu par téléphone")
      end
    end
  end

  context "motif collectif avec un proche créé à la volée" do
    let(:domain) { Domain::RDV_SERVICE_PUBLIC }
    let!(:organisation) { create(:organisation) }
    let!(:motif) { create(:motif, :collectif, organisation:) }
    let!(:rdv_collectif) { create(:rdv, :without_users, motif:, agents: [agent], organisation:) }
    let(:rdv_builder) { Users::RdvBuilder.new(user, { rdv_collectif_id: rdv_collectif.id }) }
    let!(:lieu) { create(:lieu, organisation:) }
    let!(:agent) { create(:agent, organisations: [organisation]) }
    let!(:user) { create(:user) }
    let(:user_attributes) do
      {
        first_name: "Léa",
        last_name: "Boubakar",
        relatives_attributes: { "0" => { first_name: "Marc", last_name: "Durant" } },
      }
    end

    it "crée la participation pour le proche" do
      form = described_class.new(user:, rdv_builder:, user_attributes:, domain:, selected_proche: "new")
      expect { form.save }.to change(Participation, :count).by(1).and change(User, :count).by(1)
      proche = user.reload.relatives.first
      expect(form.new_participation.user).to eq(proche)
      expect(rdv_collectif.reload.users).to contain_exactly(proche)
    end
  end

  context "motif collectif" do
    let(:domain) { Domain::RDV_SERVICE_PUBLIC }
    let!(:organisation) { create(:organisation) }
    let!(:motif) { create(:motif, :collectif, organisation:) }
    let!(:rdv_collectif) { create(:rdv, :without_users, motif:, agents: [agent], organisation:) }
    let(:rdv_builder) { Users::RdvBuilder.new(user, { rdv_collectif_id: rdv_collectif.id }) }
    let!(:lieu) { create(:lieu, organisation:) }
    let!(:agent) { create(:agent, organisations: [organisation]) }
    let(:creneau) { build(:creneau, :respects_booking_delays, motif: motif, starts_at: Time.zone.parse("2020-10-20 09h30"), agent:, lieu_id: lieu.id) }
    let!(:user) { create(:user) }

    before { allow(rdv_builder).to receive(:creneau).and_return(creneau) }

    it do
      form = described_class.new(user:, rdv_builder:, domain:)
      expect { form.save }.to change(Participation, :count).by(1)
      expect(form.new_participation).to be_persisted
      expect { form.new_participation.reload }.not_to raise_error
    end

    context "new_participation est appelé avant le save" do
      it "la participation est est persistée et rechargeable après save" do
        form = described_class.new(user:, rdv_builder:, domain:)
        participation = form.new_participation # déclenche la mémoisation avant le save, comme authorize dans le controler
        expect { form.save }.to change(Participation, :count).by(1)
        expect(participation).to be_persisted
        expect { participation.reload }.not_to raise_error
      end
    end
  end
end
