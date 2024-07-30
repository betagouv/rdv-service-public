RSpec.describe Anonymizer::Table do
  # context "general case" do
  #   let!(:prescripteur) { create(:prescripteur) }
  #   let!(:agent) { create(:agent, email: "agent@example.com") }
  #   let!(:absence) { create(:absence, title: "rdv perso avec mon médecin") }
  #   let!(:super_admin) { SuperAdmin.create!(email: "admin@example.com", first_name: "Francis", last_name: "Factice") }
  #   let!(:organisation) { create(:organisation, email: "email_perso_de_cnfs_alors_que_ce_champs_est_prevu_pour_une_adresse_mail_generique@example") }
  #   let!(:lieu) { create(:lieu, phone_number: "06 11 22 33 44", phone_number_formatted: "+33611223344") }
  #   let!(:user_without_password) { create(:user, encrypted_password: "") }
  #
  #   it "anonymizes all the data" do
  #     described_class.anonymize_all_data!(schema: "public")
  #
  #     expect(user_with_email.reload.full_name).to eq "[valeur anonymisée] [VALEUR ANONYMISÉE]"
  #
  #     expect(prescripteur.reload.full_name).to eq "[valeur anonymisée] [VALEUR ANONYMISÉE]"
  #     expect(agent.reload.full_name).to eq "[valeur anonymisée] [VALEUR ANONYMISÉE]"
  #     expect(agent.reload.email).to eq "email_anonymise_#{agent.id}@exemple.fr"
  #     expect(super_admin.reload.email).to eq "email_anonymise_#{super_admin.id}@exemple.fr"
  #     expect(organisation.reload.email).to eq "email_anonymise_#{organisation.id}@exemple.fr"
  #     expect(absence.reload.title).to eq "[valeur anonymisée]"
  #     expect(lieu.reload.phone_number).to eq "[valeur anonymisée]"
  #   end
  # end
  describe "#anonymize_record!" do
    context "prescripteur" do
      let!(:prescripteur) { create(:prescripteur) }

      it "anonymizes first and last name" do
        Anonymizer::Table.new("prescripteurs").anonymize_record!(prescripteur)
        expect(prescripteur.reload.full_name).to eq "[valeur anonymisée] [VALEUR ANONYMISÉE]"
      end
    end

    context "user with email" do
      let!(:user_with_email) { create(:user, email: "user@example.com") }

      Anonymizer::Table.new("prescripteurs").anonymize_record!(prescripteur)

      expect(user_with_email.reload.full_name).to eq "[valeur anonymisée] [VALEUR ANONYMISÉE]"
    end
  end
end
