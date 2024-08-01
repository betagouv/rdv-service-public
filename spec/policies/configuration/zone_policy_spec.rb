RSpec.describe Configuration::ZonePolicy, type: :policy do
  %i[new? create? destroy?].each do |action|
    describe "##{action}" do
      context "agent does not have any territorial role" do
        let(:territory) { create(:territory) }
        let(:sector) { create(:sector, territory:) }
        let(:zone) { create(:zone, sector:) }
        let(:agent) { create(:agent) }
        let(:agent_territorial_context) { AgentTerritorialContext.new(agent, territory) }

        it "does not permit #{action}" do
          expect(described_class.new(agent_territorial_context, zone).send(action)).to eq false
        end
      end

      context "agent has territorial role in zone territory" do
        let(:territory) { create(:territory) }
        let(:sector) { create(:sector, territory:) }
        let(:zone) { create(:zone, sector:) }
        let(:agent) { create(:agent, role_in_territories: [territory]) }
        let(:agent_territorial_context) { AgentTerritorialContext.new(agent, territory) }

        it "permits #{action}" do
          expect(described_class.new(agent_territorial_context, zone).send(action)).to eq true
        end
      end

      context "agent has territorial role in other territory" do
        let(:territory_zone) { create(:territory) }
        let(:territory_agent) { create(:territory) }
        let(:sector) { create(:sector, territory: territory_zone) }
        let(:zone) { create(:zone, sector:) }
        let(:agent) { create(:agent, role_in_territories: [territory_agent]) }

        context "context uses agent's territory" do
          let(:agent_territorial_context) { AgentTerritorialContext.new(agent, territory_agent) }

          it "does not permit #{action}" do
            expect(described_class.new(agent_territorial_context, zone).send(action)).to eq false
          end
        end

        context "context uses zone's territory" do
          let(:agent_territorial_context) { AgentTerritorialContext.new(agent, territory_zone) }

          it "does not permit #{action}" do
            expect(described_class.new(agent_territorial_context, zone).send(action)).to eq false
          end
        end
      end
    end
  end
end
