describe Users::CreneauxSearch, type: :service do
  describe "#creneaux" do
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
  end
end
