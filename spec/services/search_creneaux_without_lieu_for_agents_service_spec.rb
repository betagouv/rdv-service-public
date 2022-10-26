# frozen_string_literal: true

describe SearchCreneauxWithoutLieuForAgentsService, type: :service do
  describe "creneaux" do
    let(:form) do
      instance_double(
        AgentCreneauxSearchForm,
        organisation: organisation,
        motif: motif,
        service: motif.service,
        agent_ids: [],
        team_ids: [],
        lieu_ids: nil,
        date_range: Time.zone.today..7.days.since
      )
    end
    let(:organisation) { create(:organisation) }
    let(:motif) { create :motif, :by_phone, organisation: organisation }
    let!(:plage_ouverture) { create(:plage_ouverture, first_day: Time.zone.tomorrow, motifs: [motif], lieu: nil, organisation: organisation) }

    it "has results" do
      expect(described_class.perform_with(form).creneaux).to be_any
    end
  end
end
