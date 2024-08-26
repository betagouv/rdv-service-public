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
      allow(Users::CreneauxSearch).to receive(:creneau_for).with(
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
          expect(rdv_wizard.errors.full_messages.join(", ")).to eq("Aucun usager n’a de numéro de téléphone renseigné alors que le rendez-vous est téléphonique.")
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
