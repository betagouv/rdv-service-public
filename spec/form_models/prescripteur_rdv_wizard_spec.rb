RSpec.describe PrescripteurRdvWizard do
  let(:organisation) { create(:organisation) }
  let(:motif) { create(:motif, organisation: organisation) }
  let(:lieu) { create(:lieu, organisation: organisation) }
  let(:first_day) { Date.parse("2023/08/01") }
  let(:plage_ouverture) { create(:plage_ouverture, first_day: first_day, motifs: [motif], lieu: lieu, organisation: organisation) }

  let(:attributes) do
    {
      starts_at: plage_ouverture.starts_at,
      motif_id: motif.id,
      lieu_id: lieu.id,
      user: {
        first_name: "Léa",
        last_name: "Boubakar",
        phone_number: "06 11 22 33 44",
      },
      prescripteur: {
        first_name: "Pres",
        last_name: "Cripteur",
        email: "pres@gmail.com",
      },
      departement: "62",
      city_code: "62100",
    }
  end

  before { travel_to(first_day.beginning_of_day) }

  context "when the user already exists but with different case or accents in their name" do
    let!(:user) do
      create(:user, first_name: "Lea", last_name: "BOUBAKAR", phone_number: "0611223344")
    end

    it "adds the rdv to the user" do
      wizard = described_class.new(attributes, Domain::ALL.first)
      expect { wizard.create! }.to change(Rdv, :count).by(1)

      expect(Rdv.last.users.first).to eq(user)
    end
  end

  context "when the existing users have a different first name, last name or phone number" do
    before do
      create(:user, first_name: "Leo", last_name: "BOUBAKAR", phone_number: "0611223344")
      create(:user, first_name: "Léa", last_name: "BOUBAKA", phone_number: "0611223344")
      create(:user, first_name: "Léa", last_name: "BOUBAKAR", phone_number: "0688889999")
    end

    it "creates a new user" do
      wizard = described_class.new(attributes, Domain::ALL.first)
      expect { wizard.create! }.to change(User, :count).by(1)
    end
  end
end
