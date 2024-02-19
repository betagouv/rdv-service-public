RSpec.describe Admin::RdvSearchForm do
  describe "#to_query" do
    it "return query with lieu" do
      organisation = create(:organisation)
      lieu = create(:lieu, organisation: organisation)
      motif = create(:motif, organisation: organisation)

      agent_rdv_search_form = described_class.new(organisation_id: organisation.id, lieu_ids: [lieu.id], motif_ids: [motif.id])

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
