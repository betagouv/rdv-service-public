RSpec.describe RdvEndingShortlyBeforePresenter, type: :presenter do
  let(:presenter) { described_class.new(rdv: rdv, agent: agent, rdv_context: rdv_context, agent_context: agent_context) }

  describe "#warning_message" do
    subject { presenter.warning_message }

    before do
      dbl = instance_double(Agent::RdvPolicy::DepartementScope, resolve: rdv_in_scope ? [rdv] : [])
      allow(Agent::RdvPolicy::DepartementScope).to receive(:new).with(agent_context, Rdv).and_return(dbl)
    end

    context "same agent (=> in scope)" do
      let(:rdv_in_scope) { true }
      let!(:organisation) { create(:organisation) }
      let(:agent_context) { instance_double(AgentOrganisationContext, agent: agent, organisation: organisation) }
      let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
      let!(:user) { create(:user, first_name: "Milos", last_name: "FORMAN") }
      let!(:rdv_context) { create(:rdv, organisation: organisation, agents: [agent], starts_at: Time.zone.today.next_week(:monday).in_time_zone + 9.hours) }
      let!(:rdv) { create(:rdv, organisation: organisation, agents: [agent], users: [user], starts_at: rdv_context.starts_at - 1.hour, duration_in_min: 30) }

      it { is_expected.to match(%r{Vous avez <a .*>un RDV</a> finissant à 08h30 avec Milos FORMAN, vous allez laisser un trou de 30 minutes dans votre agenda}) }
    end

    context "rdv from other agent but still in scope" do
      let(:rdv_in_scope) { true }
      let!(:organisation) { create(:organisation) }
      let(:agent_context) { instance_double(AgentOrganisationContext, agent: build(:agent), organisation: organisation) }
      let!(:user) { create(:user, first_name: "Milos", last_name: "FORMAN") }
      let!(:rdv_context) { create(:rdv, organisation: organisation, starts_at: Time.zone.today.next_week(:monday).in_time_zone + 9.hours) }
      let!(:agent) { create(:agent, first_name: "Maya", last_name: "JOAO", basic_role_in_organisations: [organisation]) }
      let!(:rdv) { create(:rdv, organisation: organisation, agents: [agent], users: [user], starts_at: rdv_context.starts_at - 1.hour, duration_in_min: 30) }

      it { is_expected.to match(%r{Maya JOAO a <a .*>un RDV</a> finissant à 08h30 avec Milos FORMAN, vous allez laisser un trou de 30 minutes dans son agenda}) }
    end

    context "rdv from other agent and not in scope" do
      let(:rdv_in_scope) { false }
      let!(:organisation) { create(:organisation) }
      let(:agent_context) { instance_double(AgentOrganisationContext, agent: build(:agent), organisation: organisation) }
      let!(:user) { create(:user, first_name: "Milos", last_name: "FORMAN") }
      let!(:rdv_context) { create(:rdv, organisation: organisation, starts_at: Time.zone.today.next_week(:monday).in_time_zone + 9.hours) }
      let!(:agent) { create(:agent, first_name: "Maya", last_name: "JOAO", basic_role_in_organisations: [organisation]) }
      let!(:rdv) { create(:rdv, organisation: organisation, agents: [agent], users: [user], starts_at: rdv_context.starts_at - 1.hour, duration_in_min: 30) }

      it {
        expect(subject).to eq "Maya JOAO a un RDV finissant à 08h30, vous allez laisser un trou de 30 minutes dans son agenda " \
                              "(ce RDV est dans un autre service ou une autre organisation à laquelle vous n'avez pas accès)"
      }
    end
  end
end
