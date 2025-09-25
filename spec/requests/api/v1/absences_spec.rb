RSpec.describe "Plage ouvertures API" do
  let!(:oauth_token) { create(:access_token, resource_owner_id: agent.id, application:) }
  let(:headers) do
    { "Content-Type": "application/json", Authorization: "Bearer #{oauth_token.plaintext_token}" }
  end
  let(:application) { create(:oauth_application) }

  let!(:agent) { create(:agent, basic_role_in_organisations: [create(:organisation)]) }

  describe "#create" do
    let(:params) do
      {
        title: "Congé",
        first_day: Time.zone.today.strftime("%Y-%m-%d"),
        end_day: Time.zone.today.strftime("%Y-%m-%d"),
        start_time: "08:00",
        end_time: "12:00",
        agent_id: agent.id,

        external_reference: { external_id: "123" },
      }
    end

    context "when there already is an absence with this external reference" do
      let(:previous_absence) { create(:absence) }

      before do
        create(:external_reference, item: previous_absence, external_id: 123, oauth_application: application)
      end

      it "doesn't create the absence" do
        expect { post "/api/v1/absences", headers:, params:, as: :json }.not_to change(Absence, :count)
      end
    end
  end
end
