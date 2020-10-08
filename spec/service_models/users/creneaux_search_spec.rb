describe Users::CreneauxSearch, type: :service do
  let(:user) { create(:user) }
  let(:organisation) { create(:organisation) }
  let(:lieu) { create(:lieu, organisation: organisation) }
  let(:motif1) { create(:motif, name: "Coucou", organisation: organisation) }
  let(:motif2) { create(:motif, name: "Coucou", organisation: organisation) }
  let(:date_range) { (Date.parse("2020-10-20")..Date.parse("2020-10-23")) }

  subject do
    Users::CreneauxSearch
      .new(user: user, motifs: [motif1, motif2], lieu: lieu, date_range: date_range)
      .creneaux
  end

  it "call builder without special options" do
    expect(CreneauxBuilderService).to receive(:perform_with)
      .with("Coucou", lieu, date_range)
    subject
  end

  context "follow_up motif" do
    let(:motif) { create(:motif, name: "Coucou", follow_up: true, organisation: organisation) }
    subject do
      Users::CreneauxSearch
        .new(user: user, motifs: [motif], lieu: lieu, date_range: date_range)
        .creneaux
    end

    context "logged in user" do
      context "with referents" do
        let!(:agent) { create(:agent, organisations: [organisation]) }
        let(:user) { create(:user, organisations: [organisation], agents: [agent]) }

        it "should call builder with agent options" do
          expect(CreneauxBuilderService).to receive(:perform_with)
            .with("Coucou", lieu, date_range, agent_ids: [agent.id], agent_name: true)
          subject
        end
      end

      context "without referents" do
        let(:user) { create(:user, agents: []) }

        it "should call builder with agent options" do
          expect(CreneauxBuilderService).to receive(:perform_with)
            .with("Coucou", lieu, date_range, agent_ids: [], agent_name: true)
          subject
        end
      end
    end

    context "offline user" do
      let(:user) { nil }
      it "should call builder without agent options" do
        expect(CreneauxBuilderService).to receive(:perform_with)
          .with("Coucou", lieu, date_range)
        subject
      end
    end
  end

  context "with geo search" do
    let(:mock_geo_search) { instance_double(Users::GeoSearch, attributed_agents_by_organisation: attributed_agents_by_organisation) }

    subject do
      Users::CreneauxSearch
        .new(user: user, motifs: [motif1], lieu: lieu, date_range: date_range, geo_search: mock_geo_search)
        .creneaux
    end

    context "organisation is not within attributed_agents_by_organisation" do
      let(:attributed_agents_by_organisation) { {} }

      it "calls builder without agent_ids params" do
        expect(CreneauxBuilderService).to receive(:perform_with)
          .with("Coucou", lieu, date_range)
        subject
      end
    end

    context "no attributed agents" do
      let(:attributed_agents_by_organisation) { { organisation => Agent.none } }

      it "calls builder with empty agent_ids" do
        expect(CreneauxBuilderService).to receive(:perform_with)
          .with("Coucou", lieu, date_range, agent_ids: [])
        subject
      end
    end

    context "some attributed agents" do
      let!(:agent1) { create(:agent, organisations: [organisation]) }
      let!(:agent2) { create(:agent, organisations: [organisation]) }
      let(:attributed_agents_by_organisation) { { organisation => Agent.where(id: [agent1.id, agent2.id]) } }

      it "calls builder with these agents ids" do
        expect(CreneauxBuilderService).to receive(:perform_with)
          .with("Coucou", lieu, date_range, agent_ids: array_including(agent1.id, agent2.id))
        subject
      end

      context "follow_up motif" do
        let(:motif1) { create(:motif, name: "Coucou", follow_up: true, organisation: organisation) }

        context "user has agent1 as referent" do
          let(:user) { create(:user, organisations: [organisation], agents: [agent1]) }

          it "should call builder with agent1 id" do
            expect(CreneauxBuilderService).to receive(:perform_with)
              .with("Coucou", lieu, date_range, agent_ids: [agent1.id], agent_name: true)
            subject
          end
        end

        context "user has both agents as referents" do
          let(:user) { create(:user, organisations: [organisation], agents: [agent1, agent2]) }

          it "should call builder with both agents ids" do
            expect(CreneauxBuilderService).to receive(:perform_with)
              .with("Coucou", lieu, date_range, agent_ids: array_including(agent1.id, agent2.id), agent_name: true)
            subject
          end
        end

        context "user has no referent agents" do
          let(:user) { create(:user, organisations: [organisation], agents: []) }

          it "should call builder with both agents ids" do
            expect(CreneauxBuilderService).to receive(:perform_with)
              .with("Coucou", lieu, date_range, agent_ids: [], agent_name: true)
            subject
          end
        end
      end
    end
  end
end
