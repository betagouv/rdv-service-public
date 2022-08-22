# frozen_string_literal: true

describe AddConseillerNumerique do
  before do
    create(:territory, name: "Conseillers Numériques")
    create(:service, :conseiller_numerique)
    stub_request(
      :get,
      "https://api-adresse.data.gouv.fr/search/?postcode=75019&q=16%20quai%20de%20la%20Loire,%2075019%20Paris"
    ).to_return(status: 200, body: File.read(Rails.root.join("spec/support/geocode_result.json")), headers: {})
  end

  let(:params) do
    {
      external_id: "exemple@conseiller-numerique.fr",
      email: "exemple@conseiller-numerique.fr",
      first_name: "Camille",
      last_name: "Clavier",
      structure: {
        external_id: "123456",
        name: "France Service 19e",
        address: "16 quai de la Loire, 75019 Paris",
      },
    }
  end

  context "when the conseiller numerique and their structure have never been imported before" do
    it "creates the agent for the conseiller numerique" do
      described_class.process!(params)
      expect(Agent.count).to eq 1
      expect(Agent.last).to have_attributes(
        external_id: "exemple@conseiller-numerique.fr",
        email: "exemple@conseiller-numerique.fr",
        first_name: "Camille",
        last_name: "Clavier"
      )

      expect(Organisation.last).to have_attributes(
        external_id: "123456",
        name: "France Service 19e"
      )

      expect(Agent.last.roles.last).to have_attributes(
        level: "admin",
        organisation_id: Organisation.last.id
      )
    end
  end

  describe "special cases for the agent" do
    context "when the conseiller numerique has already been imported" do
      context "and they still exists with the same email" do
        before { create(:agent, external_id: "exemple@conseiller-numerique.fr") }

        it "does nothing" do
          expect { described_class.process!(params) }.not_to change(Agent, :count)
        end
      end

      context "and their account has been deleted by mistake before the external id was set" do
        before { create(:agent, external_id: nil, deleted_at: 1.day.ago) }

        it "creates a new agent, and assigns them to the organisation" do
          described_class.process!(params)
          expect(Agent.count).to eq 2
          expect(Agent.last).to have_attributes(
            external_id: "exemple@conseiller-numerique.fr",
            email: "exemple@conseiller-numerique.fr",
            first_name: "Camille",
            last_name: "Clavier"
          )

          expect(Agent.last.roles.count).to eq 1
        end
      end
    end
  end

  describe "special cases for organisations" do
    context "when there is already an organisation with this external id" do
      before { create(:organisation, external_id: "123456") }

      it "does nothing" do
        expect { described_class.process!(params) }.not_to change(Organisation, :count)
      end
    end
  end
end
