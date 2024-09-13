RSpec.describe Anonymizer::Core do
  let!(:user_with_email) { create(:user, notification_email: "user@example.com") }

  stub_env_with(HOST: nil)

  context "general case" do
    let!(:prescripteur) { create(:prescripteur) }
    let!(:agent) { create(:agent, email: "agent@example.com") }
    let!(:absence) { create(:absence, title: "rdv perso avec mon médecin") }
    let!(:super_admin) { SuperAdmin.create!(email: "admin@example.com", first_name: "Francis", last_name: "Factice") }
    let!(:organisation) { create(:organisation, email: "email_perso_de_cnfs_alors_que_ce_champs_est_prevu_pour_une_adresse_mail_generique@example") }
    let!(:lieu) { create(:lieu, phone_number: "06 11 22 33 44", phone_number_formatted: "+33611223344") }
    let!(:user_without_password) { create(:user, encrypted_password: "") }

    it "anonymizes all the data" do
      described_class.anonymize_all_data!(service: "rdvsp", schema: "public")

      expect(user_with_email.reload.full_name).to eq "[valeur anonymisée] [VALEUR ANONYMISÉE]"

      expect(prescripteur.reload.full_name).to eq "[valeur anonymisée] [VALEUR ANONYMISÉE]"
      expect(agent.reload.full_name).to eq "[valeur anonymisée] [VALEUR ANONYMISÉE]"
      expect(agent.reload.email).to eq "email_anonymise_#{agent.id}@exemple.fr"
      expect(super_admin.reload.email).to eq "email_anonymise_#{super_admin.id}@exemple.fr"
      expect(organisation.reload.email).to eq "email_anonymise_#{organisation.id}@exemple.fr"
      expect(absence.reload.title).to eq "[valeur anonymisée]"
      expect(lieu.reload.phone_number).to eq "[valeur anonymisée]"
    end
  end

  it "doesn't overwrite null values, so that we can still get information from them" do
    user_without_email = create(:user, :with_no_email)

    described_class.anonymize_all_data!(service: "rdvsp", schema: "public")

    expect(user_without_email.reload.email).to be_nil
    expect(user_with_email.reload.email).to eq "email_anonymise_#{user_with_email.id}@exemple.fr"
  end

  describe "null and empty values" do
    let!(:rdv_with_context) { create(:rdv, context: "Des infos sensisbles sur le rdv") }
    let!(:rdv_with_blank_context) { create(:rdv, context: "") }
    let!(:rdv_with_null_context) { create(:rdv, context: nil) }

    it "turns blank strings into null to avoid confusion when non-tech people use the data in metabase" do
      described_class.anonymize_all_data!(service: "rdvsp", schema: "public")

      expect(rdv_with_context.reload.context).to eq "[valeur anonymisée]"
      expect(rdv_with_blank_context.reload.context).to be_nil
      expect(rdv_with_null_context.reload.context).to be_nil
    end
  end

  context "when the environment looks like production" do
    stub_env_with(HOST: "http://www.rdv-solidarites-test.localhost")

    it "raises an error and quits" do
      expect do
        described_class.anonymize_all_data!(service: "rdvsp", schema: "public")
      end.to raise_error(RuntimeError, "Attention, il semble que vous êtes en train d'anonymiser des données d'une appli web")
    end
  end
end
