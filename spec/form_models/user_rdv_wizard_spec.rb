# frozen_string_literal: true

describe UserRdvWizard do
  let!(:organisation) { create(:organisation) }
  let!(:user) { create(:user) }
  let!(:user_for_rdv) { create(:user) }
  let!(:motif) { create(:motif, organisation: organisation) }
  let!(:lieu) { create(:lieu, organisation: organisation) }
  let!(:creneau) { build(:creneau, :respects_booking_delays, motif: motif, starts_at: Time.zone.parse("2020-10-20 09h30")) }
  let!(:plage_ouverture) { create(:plage_ouverture, motifs: [motif], lieu: lieu, organisation: organisation) }
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

  describe "#new" do
    it "works" do
      returned_creneau = Creneau.new

      allow(Users::GeoSearch).to receive(:new)
        .with(departement: "62", city_code: "62100")
        .and_return(mock_geo_search)
      allow(Users::CreneauSearch).to receive(:creneau_for).with(
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
    it "return true when everything is ok" do
      motif = create(:motif, :at_public_office, organisation: organisation)
      attributes = {
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
      rdv_wizard = UserRdvWizard::Step1.new(user, attributes)
      expect(rdv_wizard.save).to be true
    end

    it "return false with a rdv by_phone and user without phone" do
      motif = create(:motif, :by_phone, organisation: organisation)
      attributes = {
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
      rdv_wizard = UserRdvWizard::Step1.new(user, attributes)
      expect(rdv_wizard.save).to be false
      expect(rdv_wizard.errors.full_messages.join(", ")).to eq("Aucun usager n’a de numéro de téléphone renseigné alors que le rendez-vous est téléphonique.")
    end
  end
end
