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
      let!(:user) { create(:user, email: "user@example.com", first_name: "jean", last_name: "jacques", confirmation_token: "CONFIRM_ME") }

      it "anonymizes first and last name" do
        Anonymizer.anonymize_record!(user)
        expect(user.reload.full_name).to eq "[valeur anonymisée] [VALEUR ANONYMISÉE]"
        expect(user.reload.email).to eq "email_anonymise_#{user.id}@exemple.fr"
      end

      it "anonymizes unique confirmation_token" do
        Anonymizer.anonymize_record!(user)
        expect(user.reload.confirmation_token).to eq "[valeur unique anonymisée #{user.id}]"
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
    context "users" do
      let!(:user1) { create(:user, email: "user@example.com", first_name: "jean", last_name: "jacques", confirmation_token: "CONFIRM_ME") }
      let!(:user2) { create(:user, email: "user2@example.com", first_name: "marco", last_name: "polo", confirmation_token: "WAT") }
      let!(:user_without_email) { create(:user, email: nil) }

      it "anonymizes correct things" do
        Anonymizer.anonymize_records!(User.all)
        expect(user1.reload.full_name).to eq "[valeur anonymisée] [VALEUR ANONYMISÉE]"
        expect(user2.reload.full_name).to eq "[valeur anonymisée] [VALEUR ANONYMISÉE]"
        expect(user_without_email.reload.full_name).to eq "[valeur anonymisée] [VALEUR ANONYMISÉE]"
        expect(user1.reload.email).to eq "email_anonymise_#{user1.id}@exemple.fr"
        expect(user2.reload.email).to eq "email_anonymise_#{user2.id}@exemple.fr"
        expect(user_without_email.reload.email).to be_nil
        expect(user1.reload.confirmation_token).to eq "[valeur unique anonymisée #{user1.id}]"
        expect(user2.reload.confirmation_token).to eq "[valeur unique anonymisée #{user2.id}]"
      end
    end

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
      before do
        travel_to(Date.new(2020, 6, 6)) { create(:rdv) }
        travel_to(Date.new(2020, 6, 6)) { create(:rdv) }
        travel_to(Date.new(2021, 6, 6)) { create(:rdv) }
        travel_to(Date.new(2021, 6, 6)) { create(:rdv) }
      end

      context "anonymize all (scope = all)" do
        it "truncates all versions" do
          expect(PaperTrail::Version.count).to be > 4
          Anonymizer.anonymize_records!(PaperTrail::Version.all)
          expect(PaperTrail::Version.count).to eq 0
        end
      end

      context "anonymize only 2020 versions (partial scope)" do
        it "does not truncate 2021 ones" do
          expect(PaperTrail::Version.where(item_type: "Rdv").map(&:created_at).map(&:year).uniq).to eq [2020, 2021]
          Anonymizer.anonymize_records!(PaperTrail::Version.where("created_at <= ?", Date.new(2020, 12, 12)))
          expect(PaperTrail::Version.where(item_type: "Rdv").map(&:created_at).map(&:year).uniq).to eq [2021]
        end
      end
    end
  end
end
