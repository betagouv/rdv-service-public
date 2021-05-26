# frozen_string_literal: true

describe Admin::UserSearchForm do
  describe "#to_query" do
    it "return query" do
      organisation = create(:organisation)

      user_search_form = described_class.new(organisation_id: organisation.id)
      expected_query = {
        agent_id: nil,
        organisation_id: organisation.id,
        search: nil
      }
      expect(user_search_form.to_query).to eq(expected_query)
    end
  end

  describe "#users" do
    it "call User.within_organisation" do
      organisation = create(:organisation)
      user_search_form = described_class.new(organisation_id: organisation.id)
      expect(User).to receive(:within_organisation).with(organisation)
      user_search_form.users
    end

    it "call User.with_referent" do
      agent = create(:agent)
      organisation = create(:organisation)
      user_search_form = described_class.new(organisation_id: organisation.id, agent_id: agent.id)
      expect(User).to receive(:with_referent).with(agent)
      user_search_form.users
    end

    it "call User.search_by_text when search params given" do
      organisation = create(:organisation)
      user_search_form = described_class.new(organisation_id: organisation.id, search: "henri")
      expect(User).to receive(:search_by_text).with("henri")
      user_search_form.users
    end
  end
end
