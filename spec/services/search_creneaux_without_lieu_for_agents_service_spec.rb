# frozen_string_literal: true

describe SearchCreneauxWithoutLieuForAgentsService, type: :service do
  describe "creneaux" do
    before do
      travel_to(Time.zone.local(2022, 10, 15, 10, 0, 0))
    end

    let(:form) do
      instance_double(
        AgentCreneauxSearchForm,
        organisation: organisation,
        motif: motif,
        service: motif.service,
        agent_ids: [],
        team_ids: [],
        lieu_ids: nil,
        date_range: Date.new(2022, 10, 20)..Date.new(2022, 10, 30)
      )
    end
    let(:organisation) { create(:organisation) }
    let(:motif) { create :motif, :by_phone, organisation: organisation }
    let!(:plage_ouverture) { create(:plage_ouverture, motifs: [motif], first_day: Date.new(2022, 10, 25), lieu: nil, organisation: organisation) }

    it "has results" do
      expect(described_class.perform_with(form).creneaux).to be_any
    end
  end
end
