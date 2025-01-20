RSpec.describe UserRdvWizard do
  let!(:organisation) { create(:organisation) }
  let!(:user) { create(:user) }
  let!(:user_for_rdv) { create(:user) }
  let!(:motif) { create(:motif, organisation: organisation) }
  let!(:lieu) { create(:lieu, organisation: organisation) }
  let!(:creneau) { build(:creneau, :respects_booking_delays, motif: motif, starts_at: Time.zone.parse("2020-10-20 09h30")) }
  let!(:plage_ouverture) { create(:plage_ouverture, motifs: [motif], lieu: lieu, organisation: organisation) }

  describe "#new" do
    let(:mock_geo_search) { instance_double(Users::GeoSearch) }
    let(:attributes) do
      {
        starts_at: creneau.starts_at,
        motif_id: motif.id,
        lieu_id: lieu.id,
        user_ids: [user_for_rdv.id],
        departement: "62",
        city_code: "62100",
      }
    end

    it "works" do
      returned_creneau = Creneau.new

      allow(Users::GeoSearch).to receive(:new)
        .with(departement: "62", city_code: "62100")
        .and_return(mock_geo_search)
      allow(CreneauxSearch::ForUser).to receive(:creneau_for).with(
        user: user,
        motif: motif,
        lieu: lieu,
        starts_at: Time.zone.parse("2020-10-20 09h30"),
        geo_search: mock_geo_search
      ).and_return(returned_creneau)
      rdv_wizard = UserRdvWizard::Step1.new(user, attributes)
      expect(rdv_wizard.rdv.user_ids).to eq [user_for_rdv.id]
      expect(rdv_wizard.creneau).to eq returned_creneau
    end
  end

  describe "Step1#save" do
    context "when everything is ok" do
      let(:motif) { create(:motif, :at_public_office, organisation: organisation) }
      let(:attributes) do
        {
          starts_at: creneau.starts_at,
          motif_id: motif.id,
          lieu_id: lieu.id,
          user_ids: [user_for_rdv.id],
          user: {
            first_name: "Léa",
            last_name: "Boubakar",
            phone_number: nil,
          },
          departement: "62",
          city_code: "62100",
        }
      end

      it { expect(UserRdvWizard::Step1.new(user, attributes).save).to be true }
    end

    context "pour un RDV de passeport ANTS Mairie" do
      include_context "rdv_mairie_api_authentication"
      let!(:territory) { create(:territory, :mairies) }
      let!(:organisation) { create(:organisation, territory:, name: "Mairie de Wavignies") }
      let!(:motif_category) { create(:motif_category, :passeport) }
      let!(:motif) { create(:motif, organisation:, motif_category:) }

      context "l’usager fournit un numéro de pré-demande valide" do
        before { stub_ants_status_ok("VALID12345", status: "validated", appointments: []) }

        let(:attributes) do
          {
            starts_at: creneau.starts_at,
            motif_id: motif.id,
            lieu_id: lieu.id,
            user_ids: [user_for_rdv.id],
            user: {
              first_name: "Léa",
              last_name: "Boubakar",
              phone_number: "0612345678",
              ants_pre_demande_number: "VALID12345",
            },
            departement: "62",
            city_code: "62100",
          }
        end

        it { expect(UserRdvWizard::Step1.new(user, attributes).save).to be true }
      end

      context "l’usager fournit un numéro de pré-demande vide" do
        let(:attributes) do
          {
            starts_at: creneau.starts_at,
            motif_id: motif.id,
            lieu_id: nil,
            user_ids: [user_for_rdv.id],
            user: {
              first_name: "Léa",
              last_name: "Boubakar",
              phone_number: "0612345678",
              ants_pre_demande_number: "",
            },
            departement: "62",
            city_code: "62100",
          }
        end

        it "empêche la création" do
          form = UserRdvWizard::Step1.new(user, attributes)
          res = form.save
          expect(res).to be false
          expect(form.errors.count).to eq(1)
          expect(form.errors.first.attribute).to eq(:ants_pre_demande_number)
          expect(form.errors.first.message).to eq("doit comporter 10 chiffres et lettres")
          # le message affiché est en fait celui sur le user
          expect(form.errors.first.full_message).to eq("Numéro de pré-demande ANTS doit comporter 10 chiffres et lettres")
        end
      end

      context "l’usager fournit un numéro de pré-demande ANTS non reconnu" do
        before { stub_ants_status_ok("VALID12345", status: "unknown", appointments: []) }

        let(:attributes) do
          {
            starts_at: creneau.starts_at,
            motif_id: motif.id,
            lieu_id: nil,
            user_ids: [user_for_rdv.id],
            user: {
              first_name: "Léa",
              last_name: "Boubakar",
              phone_number: "0612345678",
              ants_pre_demande_number: "VALID12345",
            },
            departement: "62",
            city_code: "62100",
          }
        end

        it "empêche la création" do
          form = UserRdvWizard::Step1.new(user, attributes)
          res = form.save
          expect(res).to be false
          expect(form.errors.count).to eq(1)
          expect(form.errors.first.attribute).to eq(:ants_pre_demande_number)
          expect(form.errors.first.full_message).to eq("Numéro de pré-demande ANTS n'est pas reconnu par l'ANTS")
        end
      end

      context "l’usager fournit un numéro de pré-demande ANTS qui a déjà un appointment" do
        before do
          stub_ants_status_ok(
            "VALID12345",
            status: "validated",
            appointments: [{ "meeting_point" => "Mairie de Montrouge", "management_url" => "http://rdvsympa.fr/123" }]
          )
        end

        let(:attributes) do
          {
            starts_at: creneau.starts_at,
            motif_id: motif.id,
            lieu_id: nil,
            user_ids: [user_for_rdv.id],
            user: {
              first_name: "Léa",
              last_name: "Boubakar",
              phone_number: "0612345678",
              ants_pre_demande_number: "VALID12345",
            },
            departement: "62",
            city_code: "62100",
          }
        end

        it "empêche la création" do
          form = UserRdvWizard::Step1.new(user, attributes)
          res = form.save
          expect(res).to be false
          expect(form.errors.count).to eq(1)
          expect(form.errors.first.attribute).to eq(:_benign)
          expect(form.errors.first.message).to eq(
            <<-TXT.squish
              Ce numéro de pré-demande ANTS est déjà utilisé pour un RDV auprès de Mairie de Montrouge.
              Veuillez <a href="http://rdvsympa.fr/123" target="_blank">annuler ce RDV<a> avant d'en prendre un nouveau.
          TXT
          )
        end
      end

      context "l’usager fournit un numéro de pré-demande ANTS qui a déjà un appointment mais ignore les avertissements" do
        before do
          stub_ants_status_ok(
            "VALID12345",
            status: "validated",
            appointments: [{ "meeting_point" => "Mairie de Montrouge", "management_url" => "http://rdvsympa.fr/123" }]
          )
        end

        let(:attributes) do
          {
            starts_at: creneau.starts_at,
            motif_id: motif.id,
            lieu_id: nil,
            user_ids: [user_for_rdv.id],
            user: {
              first_name: "Léa",
              last_name: "Boubakar",
              phone_number: "0612345678",
              ants_pre_demande_number: "VALID12345",
              ignore_benign_errors: "true",
            },
            departement: "62",
            city_code: "62100",
          }
        end

        it "n’empêche pas la création" do
          form = UserRdvWizard::Step1.new(user, attributes)
          res = form.save
          expect(res).to be true
        end
      end

      context "l’usager fournit un numéro de pré-demande ANTS valide mais l’API ANTS timeout" do
        before { allow(AntsApi).to receive(:status).and_raise(Typhoeus::Errors::TimeoutError) }

        let(:attributes) do
          {
            starts_at: creneau.starts_at,
            motif_id: motif.id,
            lieu_id: nil,
            user_ids: [user_for_rdv.id],
            user: {
              first_name: "Léa",
              last_name: "Boubakar",
              phone_number: "0612345678",
              ants_pre_demande_number: "VALID12345",
            },
            departement: "62",
            city_code: "62100",
          }
        end

        it "empêche la création" do
          form = UserRdvWizard::Step1.new(user, attributes)
          res = form.save
          expect(res).to be false
          expect(form.errors.count).to eq(1)
          expect(form.errors.first.attribute).to eq(:ants_pre_demande_number)
          expect(form.errors.first.full_message).to eq("Numéro de pré-demande ANTS n'a pas pu être validé à cause d'une erreur inattendue. Merci de réessayer dans 30 secondes.")
        end
      end
    end

    context "when the motif is by phone" do
      let(:motif) { create(:motif, :by_phone, organisation: organisation) }

      context "when the lieu is nil" do
        let(:attributes) do
          {
            starts_at: creneau.starts_at,
            motif_id: motif.id,
            lieu_id: nil,
            user_ids: [user_for_rdv.id],
            user: {
              first_name: "Léa",
              last_name: "Boubakar",
              phone_number: "0612345678",
            },
            departement: "62",
            city_code: "62100",
          }
        end

        it { expect(UserRdvWizard::Step1.new(user, attributes).save).to be true }
      end

      context "when the phone number is blank" do
        let(:attributes) do
          {
            starts_at: creneau.starts_at,
            motif_id: motif.id,
            lieu_id: lieu.id,
            user_ids: [user_for_rdv.id],
            user: {
              first_name: "Léa",
              last_name: "Boubakar",
              phone_number: nil,
            },
            departement: "62",
            city_code: "62100",
          }
        end

        it { expect(UserRdvWizard::Step1.new(user, attributes).save).to be false }

        it "return false with a rdv by_phone and user without phone" do
          rdv_wizard = UserRdvWizard::Step1.new(user, attributes)
          rdv_wizard.valid?
          expect(rdv_wizard.errors.full_messages.join(", ")).to eq("Le numéro de téléphone est obligatoire car le RDV aura lieu par téléphone")
        end
      end
    end

    context "Rdv collectif" do
      context "bookable by agents and prescripteurs" do
        let(:motif) { create(:motif, :at_public_office, organisation: organisation, bookable_by: :agents_and_prescripteurs, collectif: true) }
        let!(:rdv) { create(:rdv, motif: motif, organisation: organisation) }
        let(:attributes) { { rdv_collectif_id: rdv.id } }

        it "finds the Rdv" do
          expect(UserRdvWizard::Step1.new(user_for_rdv, attributes).rdv).to eq(rdv)
        end
      end
    end
  end
end
