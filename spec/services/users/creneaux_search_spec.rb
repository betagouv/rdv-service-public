# frozen_string_literal: true

describe Users::CreneauxSearch, type: :service do
  subject do
    described_class
      .new(user: user, motif: motif1, lieu: lieu, date_range: date_range)
      .creneaux
  end

  let(:user) { create(:user) }
  let(:organisation) { create(:organisation) }
  let(:lieu) { create(:lieu, organisation: organisation) }
  let(:motif1) { create(:motif, name: "Coucou", organisation: organisation, location_type: :public_office) }
  let(:motif2) { create(:motif, name: "Coucou", organisation: organisation, location_type: :public_office) }
  let(:date_range) { (Date.parse("2020-10-20")..Date.parse("2020-10-23")) }

  it "call builder without special options" do
    expect(CreneauxBuilderService).to receive(:perform_with)
      .with("Coucou", lieu, date_range, motif_location_type: "public_office", service: motif1.service)
    subject
  end

  context "follow_up motif" do
    subject do
      described_class
        .new(user: user, motif: motif, lieu: lieu, date_range: date_range)
        .creneaux
    end

    let(:motif) { create(:motif, name: "Coucou", follow_up: true, organisation: organisation) }

    context "logged in user" do
      context "with referents" do
        let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
        let(:user) { create(:user, organisations: [organisation], agents: [agent]) }

        it "calls builder with agent options" do
          expect(CreneauxBuilderService).to receive(:perform_with)
            .with("Coucou", lieu, date_range, agent_ids: [agent.id], agent_name: true, motif_location_type: "public_office", service: motif.service)
          subject
        end
      end

      context "without referents" do
        let(:user) { create(:user, agents: []) }

        it "calls builder with agent options" do
          expect(CreneauxBuilderService).to receive(:perform_with)
            .with("Coucou", lieu, date_range, agent_ids: [], agent_name: true, motif_location_type: "public_office", service: motif.service)
          subject
        end
      end
    end

    context "offline user" do
      let(:user) { nil }

      it "calls builder without agent options" do
        expect(CreneauxBuilderService).to receive(:perform_with)
          .with("Coucou", lieu, date_range, motif_location_type: "public_office", service: motif.service)
        subject
      end
    end
  end

  context "with geo search" do
    subject do
      described_class
        .new(user: user, motif: motif1, lieu: lieu, date_range: date_range, geo_search: mock_geo_search)
        .creneaux
    end

    let(:motif1) { create(:motif, :sectorisation_level_agent, name: "Coucou", organisation: organisation) }
    let(:mock_geo_search) { instance_double(Users::GeoSearch, attributed_agents_by_organisation: attributed_agents_by_organisation) }

    context "organisation is not within attributed_agents_by_organisation" do
      let(:attributed_agents_by_organisation) { {} }

      it "calls builder without agent_ids params" do
        expect(CreneauxBuilderService).to receive(:perform_with)
          .with("Coucou", lieu, date_range, motif_location_type: "public_office", service: motif1.service)
        subject
      end
    end

    context "no attributed agents" do
      let(:attributed_agents_by_organisation) { { organisation => Agent.none } }

      it "calls builder with empty agent_ids" do
        expect(CreneauxBuilderService).to receive(:perform_with)
          .with("Coucou", lieu, date_range, agent_ids: [], motif_location_type: "public_office", service: motif1.service)
        subject
      end
    end

    context "some attributed agents" do
      let!(:agent1) { create(:agent, basic_role_in_organisations: [organisation]) }
      let!(:agent2) { create(:agent, basic_role_in_organisations: [organisation]) }
      let(:attributed_agents_by_organisation) { { organisation => Agent.where(id: [agent1.id, agent2.id]) } }

      it "calls builder with these agents ids" do
        expect(CreneauxBuilderService).to receive(:perform_with)
          .with("Coucou", lieu, date_range, agent_ids: array_including(agent1.id, agent2.id), motif_location_type: "public_office", service: motif1.service)
        subject
      end

      context "follow_up motif" do
        let(:motif1) { create(:motif, name: "Coucou", follow_up: true, organisation: organisation) }

        context "user has agent1 as referent" do
          let(:user) { create(:user, organisations: [organisation], agents: [agent1]) }

          it "calls builder with agent1 id" do
            expect(CreneauxBuilderService).to receive(:perform_with)
              .with("Coucou", lieu, date_range, agent_ids: [agent1.id], agent_name: true, motif_location_type: "public_office", service: motif1.service)
            subject
          end
        end

        context "user has both agents as referents" do
          let(:user) { create(:user, organisations: [organisation], agents: [agent1, agent2]) }

          it "calls builder with both agents ids" do
            expect(CreneauxBuilderService).to receive(:perform_with)
              .with("Coucou", lieu, date_range, agent_ids: array_including(agent1.id, agent2.id), agent_name: true, motif_location_type: "public_office", service: motif1.service)
            subject
          end
        end

        context "user has no referent agents" do
          let(:user) { create(:user, organisations: [organisation], agents: []) }

          it "calls builder with both agents ids" do
            expect(CreneauxBuilderService).to receive(:perform_with)
              .with("Coucou", lieu, date_range, agent_ids: [], agent_name: true, motif_location_type: "public_office", service: motif1.service)
            subject
          end
        end
      end
    end
  end
end
