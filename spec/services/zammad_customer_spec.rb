RSpec.describe ZammadCustomer do
  describe ZammadCustomer::Attributes do
    describe "#find_user_or_agent_and_augment" do
      subject { described_class.new(**args).tap(&:find_user_or_agent_and_augment) }

      context "usager trouvé par email" do
        let!(:user) { create(:user, email: "soukalina@gmail.com") }
        let(:args) { { email: "soukalina@gmail.com", phone: nil } }

        specify do
          expect(subject.note).to eq "Usager trouvé avec l'email soukalina@gmail.com"
          expect(subject.super_admin_url).to eq "http://www.rdv-mairie-test.localhost/super_admins/users/#{user.id}"
        end
      end

      context "agent trouvé par email" do
        let!(:agent) { create(:agent, email: "agent@example.com") }
        let(:args) { { email: "agent@example.com", phone: nil } }

        specify do
          expect(subject.note).to eq "Agent trouvé avec l'email agent@example.com"
          expect(subject.super_admin_url).to eq "http://www.rdv-mairie-test.localhost/super_admins/agents/#{agent.id}"
        end
      end

      context "usager trouvé par numéro de téléphone" do
        let!(:user) { create(:user, phone_number: "0612345678", phone_number_formatted: "+33612345678") }

        let(:args) { { phone: "0612345678", email: nil } }

        specify do
          expect(subject.note).to eq "Usager trouvé avec le numéro de téléphone formatté +33612345678"
          expect(subject.super_admin_url).to eq "http://www.rdv-mairie-test.localhost/super_admins/users/#{user.id}"
        end
      end

      context "aucun usager ni agent trouvé" do
        let(:args) { { email: "unknown@example.com", phone: "013456789" } }

        specify do
          expect(subject.note).to eq "Aucun usager ni agent trouvé"
          expect(subject.super_admin_url).to be_nil
        end
      end

      context "la correspondance par email prévaut sur le téléphone" do
        let!(:user_by_email) { create(:user, email: "test@example.com") }
        let!(:user_by_phone) { create(:user, phone_number: "0612345678") }

        let(:args) { { email: "test@example.com", phone: "0612345678" } }

        specify do
          expect(subject.note).to eq "Usager trouvé avec l'email test@example.com"
          expect(subject.super_admin_url).to eq "http://www.rdv-mairie-test.localhost/super_admins/users/#{user_by_email.id}"
          expect(subject.super_admin_url).not_to eq "http://www.rdv-mairie-test.localhost/super_admins/users/#{user_by_phone.id}"
        end
      end

      context "usager trouvé par numéro de téléphone formatté" do
        let!(:user) { create(:user, phone_number: "06.12-34.56.78", phone_number_formatted: "+33612345678") }
        let(:args) { { phone: "06 12 34 56 78", email: nil } }

        specify do
          expect(subject.note).to eq "Usager trouvé avec le numéro de téléphone formatté +33612345678"
          expect(subject.super_admin_url).to eq "http://www.rdv-mairie-test.localhost/super_admins/users/#{user.id}"
        end
      end

      context "plusieurs usagers trouvés via le numéro de téléphone formatté" do
        let!(:user1) { create(:user, phone_number: "06.12-34.56.78", phone_number_formatted: "+33612345678") }
        let!(:user2) { create(:user, phone_number: "06.12-34.56.78", phone_number_formatted: "+33612345678kdkd") }
        let(:args) { { phone: "06 12 34 56 78", email: nil } }

        specify do
          expect(subject.note).to eq "Plusieurs usagers trouvés avec le numéro de téléphone formatté +33612345678"
          expect(subject.super_admin_url).to be_nil
        end
      end

      context "plusieurs usagers trouvés via le numéro de téléphone non formatté" do
        let!(:user1) { build(:user, phone_number: "01 23 44").tap { _1.save!(validate: false) } }
        let!(:user2) { build(:user, phone_number: "01 23 44").tap { _1.save!(validate: false) } }
        let(:args) { { phone: "01 23 44", email: nil } }

        specify do
          expect(subject.note).to eq "Plusieurs usagers trouvés avec le numéro de téléphone 01 23 44"
          expect(subject.super_admin_url).to be_nil
        end
      end

      context "usager non trouvé si numéro trop court" do
        let!(:user) { create(:user, phone_number: "0123456789") }
        let(:args) { { phone: "123", email: nil } }

        specify do
          expect(subject.note).to eq "Aucun usager ni agent trouvé"
          expect(subject.super_admin_url).to be_nil
        end
      end
    end
  end

  describe ZammadCustomer::AgentAugmenter do
    subject do
      described_class.new(agent).augment(zammad_attributes)
      zammad_attributes
    end

    let(:zammad_attributes) { ZammadCustomer::Attributes.new }

    let!(:agent) { create(:agent, email: "agent@example.com") }

    specify do
      expect(subject.note).to be_blank
      expect(subject.super_admin_url).to eq "http://www.rdv-mairie-test.localhost/super_admins/agents/#{agent.id}"
    end
  end

  describe ZammadCustomer::UserAugmenter do
    subject do
      described_class.new(user).augment(zammad_attributes)
      zammad_attributes
    end

    let(:zammad_attributes) { ZammadCustomer::Attributes.new }

    let!(:user) { create(:user, email: "agent@example.com") }

    specify do
      expect(subject.note).to be_blank
      expect(subject.super_admin_url).to eq "http://www.rdv-mairie-test.localhost/super_admins/users/#{user.id}"
    end
  end
end
