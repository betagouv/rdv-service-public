describe PlageOuverturePresenter, type: :presenter do
  describe "#overlaps_rdv_error_message" do
    subject { presenter.overlaps_rdv_error_message }

    context "in scope same organisation" do
      let!(:organisation) { create(:organisation, name: "Ivry/Seine") }
      let!(:service) { create(:service) }
      let!(:agent1) { create(:agent, services: [service], basic_role_in_organisations: [organisation]) }
      let!(:agent1_context) { AgentContext.new(agent1, organisation) }
      let!(:agent2) { create(:agent, first_name: "Jeanne", last_name: "Longo", services: [service], basic_role_in_organisations: [organisation]) }
      let!(:lieu) { create(:lieu, name: "MDS du coin", organisation: organisation) }
      let!(:plage_ouverture) do
        create(
          :plage_ouverture,
          agent: agent2,
          organisation: organisation,
          lieu: lieu,
          start_time: Tod::TimeOfDay.new(7),
          end_time: Tod::TimeOfDay.new(10),
          first_day: Date.new(2020, 12, 9)
        )
      end
      let(:presenter) { described_class.new(plage_ouverture, agent1_context) }

      it { is_expected.to match %r{Jeanne LONGO a <a href=.*>une plage d'ouverture</a> à MDS du coin mercredi 09 décembre 2020de 07:00 à 10:00} }
    end
  end
end
