RSpec.describe Anonymizer do
  describe "#anonymize_record!" do
    context "prescripteur" do
      let!(:prescripteur) { create(:prescripteur, first_name: "jean", last_name: "jacques") }

      it "anonymizes first and last name" do
        Anonymizer.anonymize_record!(prescripteur)
        expect(prescripteur.reload.full_name).to eq "[valeur anonymisée] [VALEUR ANONYMISÉE]"
        expect(prescripteur.reload.email).to eq "email_anonymise_#{prescripteur.id}@exemple.fr"
      end
    end

    context "user" do
      let!(:user) { create(:user, email: "user@example.com", first_name: "jean", last_name: "jacques") }

      it "anonymizes first and last name" do
        Anonymizer.anonymize_record!(user)
        expect(user.reload.full_name).to eq "[valeur anonymisée] [VALEUR ANONYMISÉE]"
        expect(user.reload.email).to eq "email_anonymise_#{user.id}@exemple.fr"
      end
    end

    context "user without email" do
      let(:user) { create(:user, email: nil) }

      it "doesn't overwrite null values, so that we can still get information from them" do
        Anonymizer.anonymize_record!(user)
        expect(user.reload.email).to be_nil
      end
    end

    context "agent" do
      let!(:agent) { create(:agent, email: "agent@example.com", first_name: "jean", last_name: "jacques") }

      it "anonymizes first and last name" do
        Anonymizer.anonymize_record!(agent)
        expect(agent.reload.full_name).to eq "[valeur anonymisée] [VALEUR ANONYMISÉE]"
        expect(agent.reload.email).to eq "email_anonymise_#{agent.id}@exemple.fr"
      end
    end

    context "absence" do
      let!(:absence) { create(:absence, title: "rdv perso avec mon médecin") }

      it "anonymizes title" do
        Anonymizer.anonymize_record!(absence)
        expect(absence.reload.title).to eq "[valeur anonymisée]"
      end
    end

    context "organisation" do
      let!(:organisation) { create(:organisation, email: "email_perso_de_cnfs_alors_que_ce_champs_est_prevu_pour_une_adresse_mail_generique@example") }

      it "anonymizes email" do
        Anonymizer.anonymize_record!(organisation)
        expect(organisation.reload.email).to eq "email_anonymise_#{organisation.id}@exemple.fr"
      end
    end

    context "super_admin" do
      let!(:super_admin) { create(:super_admin, email: "admin@example.com", first_name: "Francis", last_name: "Factice") }

      it "anonymizes email" do
        Anonymizer.anonymize_record!(super_admin)
        expect(super_admin.reload.email).to eq "email_anonymise_#{super_admin.id}@exemple.fr"
      end
    end

    context "lieu" do
      let!(:lieu) { create(:lieu, phone_number: "06 11 22 33 44", phone_number_formatted: "+33611223344") }

      it "anonymizes phone number" do
        Anonymizer.anonymize_record!(lieu)
        expect(lieu.reload.phone_number).to eq "[valeur anonymisée]"
      end
    end

    context "rdv with context" do
      let!(:rdv) { create(:rdv, context: "Des infos sensisbles sur le rdv") }

      it "anonymizes context" do
        Anonymizer.anonymize_record!(rdv)
        expect(rdv.reload.context).to eq "[valeur anonymisée]"
      end
    end

    context "rdv with blank context" do
      let!(:rdv) { create(:rdv, context: "") }

      it "turns blank strings into null" do
        Anonymizer.anonymize_record!(rdv)
        expect(rdv.reload.context).to be_nil
      end
    end

    context "rdv with nil context" do
      let!(:rdv) { create(:rdv, context: nil) }

      it "doesn't overwrite null values" do
        Anonymizer.anonymize_record!(rdv)
        expect(rdv.reload.context).to be_nil
      end
    end

    context "paper trail version (truncated table)" do
      let!(:version) { create(:rdv).versions.last }
      let!(:other_version) { create(:rdv).versions.last }

      it "deletes the version but not the others" do
        id = version.id
        Anonymizer.anonymize_record!(version)
        expect(PaperTrail::Version.find_by(id:)).to be_nil
        expect(PaperTrail::Version.find(other_version.id)).to eq other_version
      end
    end
  end

  describe "#anonymize_records!" do
    context "rdvs" do
      let!(:rdv_with_context) { create(:rdv, context: "Des infos sensisbles sur le rdv") }
      let!(:rdv_with_blank_context) { create(:rdv, context: "") }
      let!(:rdv_with_nil_context) { create(:rdv, context: nil) }

      it "anonymizes correctly" do
        Anonymizer.anonymize_records!(Rdv.all)
        expect(rdv_with_context.reload.context).to eq "[valeur anonymisée]"
        expect(rdv_with_blank_context.reload.context).to be_nil
        expect(rdv_with_nil_context.reload.context).to be_nil
      end
    end

    context "paper trail version (truncated table)" do
      let!(:version) { create(:rdv).versions.last }
      let!(:other_version) { create(:rdv).versions.last }

      it "truncates all versions" do
        Anonymizer.anonymize_records!(PaperTrail::Version.all)
        expect(PaperTrail::Version.count).to eq 0
      end
    end
  end
end
