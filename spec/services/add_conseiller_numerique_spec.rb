# frozen_string_literal: true

describe AddConseillerNumerique do
  let!(:territory) { create(:territory, name: "Conseillers Numériques") }
  let(:params) do
    {
      external_id: "exemple@conseiller-numerique.fr",
      email: "exemple@conseiller-numerique.fr",
      secondary_email: "mail_perso@gemelle.com",
      first_name: "Camille",
      last_name: "Clavier",
      structure: {
        external_id: "123456",
        name: "France Service 19e",
        address: "16 quai de la Loire, 75019 Paris",
      },
    }
  end

  before do
    create(:service, :conseiller_numerique)
    stub_request(
      :get,
      "https://api-adresse.data.gouv.fr/search/?postcode=75019&q=16%20quai%20de%20la%20Loire,%2075019%20Paris"
    ).to_return(status: 200, body: file_fixture("geocode_result.json").read, headers: {})
  end

  context "when the conseiller numerique and their structure have never been imported before" do
    it "creates the agent for the conseiller numerique and notifies them" do
      described_class.process!(params)
      expect(Agent.count).to eq 1
      expect(Agent.last).to have_attributes(
        external_id: "exemple@conseiller-numerique.fr",
        email: "exemple@conseiller-numerique.fr",
        cnfs_secondary_email: "mail_perso@gemelle.com",
        first_name: "Camille",
        last_name: "Clavier"
      )

      expect(Organisation.last).to have_attributes(
        external_id: "123456",
        name: "France Service 19e"
      )

      expect(Agent.last.roles.last).to have_attributes(
        access_level: "admin",
        organisation_id: Organisation.last.id
      )

      perform_enqueued_jobs
      invitation_email = ActionMailer::Base.deliveries.last

      expect(invitation_email).to have_attributes(to: ["exemple@conseiller-numerique.fr"], reply_to: ["support@rdv-aide-numerique.fr"])
    end
  end

  describe "special cases for the agent" do
    context "when the conseiller numerique has already been imported" do
      context "and they still exists with the same email" do
        before { create(:agent, external_id: "exemple@conseiller-numerique.fr") }

        it "does nothing" do
          expect { described_class.process!(params) }.not_to change { [Agent.count, Agent.maximum(:updated_at)] }
        end
      end
    end
  end

  describe "special cases for organisations" do
    context "when there is already an organisation with this external id" do
      before { create(:organisation, external_id: "123456", territory: Territory.find_by!(name: "Conseillers Numériques")) }

      it "does nothing" do
        expect { described_class.process!(params) }.not_to change(Organisation, :count)
      end
    end
  end
end
