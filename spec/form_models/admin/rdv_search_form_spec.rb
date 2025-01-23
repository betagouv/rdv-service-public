RSpec.describe Admin::RdvSearchForm do
  let(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
  let(:organisation) { create(:organisation) }
  let(:current_params) do
    { current_agent: agent, current_organisation: organisation }
  end

  describe "#user" do
    let(:user) { create(:user) }
    let(:form) { described_class.new(current_params.merge(user_id: user.id)) }

    context "when injecting the id of a user the agent can't see" do
      it "returns nil" do
        expect(form.user).to be_blank
      end
    end

    context "when the agent can see the user" do
      before { user.update!(organisations: [organisation]) }

      it "return the user" do
        expect(form.user).to eq user
      end
    end
  end

  describe "#to_query" do
    it "return query with lieu" do
      lieu = create(:lieu, organisation: organisation)
      motif = create(:motif, organisation: organisation)

      agent_rdv_search_form = described_class.new(current_params.merge(
                                                    organisation_id: organisation.id, lieu_ids: [lieu.id], motif_ids: [motif.id]
                                                  ))

      expected_query = {
        agent_id: nil,
        start: nil,
        end: nil,
        organisation_id: organisation.id,
        lieu_ids: [lieu.id],
        motif_ids: [motif.id],
        status: nil,
        user_id: nil,
        scoped_organisation_ids: nil,
      }
      expect(agent_rdv_search_form.to_query).to eq(expected_query)
    end
  end
end
