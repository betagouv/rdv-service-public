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

  context "motif ANTS" do
    let(:domain) { Domain::RDV_SERVICE_PUBLIC }
    let!(:territory) { create(:territory) }
    let!(:organisation) { create(:organisation, territory:, name: "Mairie de Wavignies") }
    let!(:motif_category) { create(:motif_category, :passeport) }
    let!(:motif) { create(:motif, organisation:, motif_category:) }
    let!(:user) { create(:user) }
    let!(:lieu) { create(:lieu, organisation: organisation) }
    let!(:agent) { create(:agent, organisations: [organisation]) }
    let(:creneau) { build(:creneau, :respects_booking_delays, motif:, agent:, lieu_id: lieu.id) }
    let(:rdv_builder) { Users::RdvBuilder.new(user, { motif_id: motif.id, lieu_id: lieu.id }) }
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
          relatives_attributes: { "0" => { first_name: "Marc", last_name: "Durant", ants_pre_demande_number: "" } },
        )
      end

      it "retourne une erreur de présence pour le proche" do
        form = described_class.new(user:, rdv_builder:, user_attributes:, domain:)
        expect(form.save).to be(false)
        expect(form.errors[:base]).to include("Proche 1 : doit être renseigné")
      end
    end

    context "avec un numéro de proche au mauvais format" do
      let(:user_attributes) do
        super().merge(
          relatives_attributes: { "0" => { first_name: "Marc", last_name: "Durant", ants_pre_demande_number: "TROP_COURT" } },
        )
      end

      it "retourne une erreur de format pour le proche" do
        form = described_class.new(user:, rdv_builder:, user_attributes:, domain:)
        expect(form.save).to be(false)
        expect(form.errors[:base]).to include("Proche 1 : doit comporter 10 chiffres et lettres")
      end
    end

    context "avec un numéro de proche au statut consommé" do
      let(:user_attributes) do
        super().merge(
          relatives_attributes: { "0" => { first_name: "Marc", last_name: "Durant", ants_pre_demande_number: "CONSOMME99" } },
        )
      end

      before { stub_ants_status_ok("CONSOMME99", status: "consumed", meeting_point_id: lieu.id, appointments: []) }

      it "retourne une erreur de statut pour le proche" do
        form = described_class.new(user:, rdv_builder:, user_attributes:, domain:)
        expect(form.save).to be(false)
        expect(form.errors[:base]).to include("Proche 1 : correspond à un dossier déjà instruit")
      end
    end
  end

  context "motif ANTS avec un proche existant sélectionné parmi plusieurs" do
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
    let!(:proches) { create_list(:user, 3, :relative, responsible: user) }
    let(:user_attributes) do
      {
        first_name: "Léa",
        last_name: "Boubakar",
        phone_number: "0612345678",
        ants_pre_demande_number: "VALID12345",
        relatives_attributes: {
          "0" => { id: proches[0].id, ants_pre_demande_number: "PROCHE6789" },
          "1" => { id: proches[1].id },
          "2" => { id: proches[2].id },
        },
      }
    end

    include_context "rdv_mairie_api_authentication"

    before do
      allow(rdv_builder).to receive(:creneau).and_return(creneau)
      stub_ants_status_ok("VALID12345", status: "validated", meeting_point_id: lieu.id, appointments: [])
      stub_ants_status_ok("PROCHE6789", status: "validated", meeting_point_id: lieu.id, appointments: [])
    end

    it "crée le RDV pour l'usager et le proche sélectionné uniquement" do
      form = described_class.new(user:, rdv_builder:, user_attributes:, domain:, ants_selected_relative_ids: [proches[0].id.to_s])
      expect { form.save }.to change(Rdv, :count).by(1)
      expect(form.rdv.users).to contain_exactly(user, proches[0])
    end
  end

  context "motif ANTS mixte : 2 proches existants sélectionnés + 2 nouveaux proches" do
    let(:domain) { Domain::RDV_SERVICE_PUBLIC }
    let!(:territory) { create(:territory) }
    let!(:organisation) { create(:organisation, territory:, name: "Mairie de Wavignies") }
    let!(:motif_category) { create(:motif_category, :passeport) }
    let!(:motif) { create(:motif, organisation:, motif_category:) }
    let!(:user) { create(:user) }
    let!(:lieu) { create(:lieu, organisation:) }
    let!(:agent) { create(:agent, organisations: [organisation]) }
    let(:creneau) { build(:creneau, :respects_booking_delays, motif:, agent:, lieu_id: lieu.id) }
    let(:rdv_builder) { Users::RdvBuilder.new(user, { motif_id: motif.id, lieu_id: lieu.id, ants_pre_demandes_count: 5 }) }
    let!(:proches) { create_list(:user, 3, :relative, responsible: user) }
    let(:user_attributes) do
      {
        first_name: "Léa",
        last_name: "Boubakar",
        phone_number: "0612345678",
        ants_pre_demande_number: "VALID12345",
        relatives_attributes: {
          "0" => { id: proches[0].id, ants_pre_demande_number: "PROCHE1000" },
          "1" => { id: proches[1].id, ants_pre_demande_number: "PROCHE2000" },
          "2" => { id: proches[2].id },
          "3" => { first_name: "Marc", last_name: "Durant", ants_pre_demande_number: "NOUVEAU001" },
          "4" => { first_name: "Julie", last_name: "Martin", ants_pre_demande_number: "NOUVEAU002" },
        },
      }
    end

    include_context "rdv_mairie_api_authentication"

    before do
      allow(rdv_builder).to receive(:creneau).and_return(creneau)
      stub_ants_status_ok("VALID12345", status: "validated", meeting_point_id: lieu.id, appointments: [])
      stub_ants_status_ok("PROCHE1000", status: "validated", meeting_point_id: lieu.id, appointments: [])
      stub_ants_status_ok("PROCHE2000", status: "validated", meeting_point_id: lieu.id, appointments: [])
      stub_ants_status_ok("NOUVEAU001", status: "validated", meeting_point_id: lieu.id, appointments: [])
      stub_ants_status_ok("NOUVEAU002", status: "validated", meeting_point_id: lieu.id, appointments: [])
    end

    it "crée le RDV pour l'usager, les 2 proches sélectionnés et les 2 nouveaux proches" do
      form = described_class.new(user:, rdv_builder:, user_attributes:, domain:, ants_selected_relative_ids: [proches[0].id.to_s, proches[1].id.to_s])
      expect { form.save }.to change(Rdv, :count).by(1).and change(User, :count).by(2)
      marc = User.find_by!(first_name: "Marc", last_name: "Durant")
      julie = User.find_by!(first_name: "Julie", last_name: "Martin")
      expect(form.rdv.users).to contain_exactly(user, proches[0], proches[1], marc, julie)
      expect(marc.created_through).to eq("user_relative_creation")
      expect(julie.created_through).to eq("user_relative_creation")
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
