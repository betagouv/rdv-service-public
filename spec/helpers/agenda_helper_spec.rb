# frozen_string_literal: true

describe AgendaHelper do
  describe "#status_to_display" do
    it "returns nil when agent prefer display all RDV" do
      agent = build(:agent, display_cancelled_rdv: true)
      expect(status_to_display(agent)).to be_nil
    end

    it "returns status not cancelled when agent prefer hide cancelled RDV" do
      agent = build(:agent, display_cancelled_rdv: false)
      expect(status_to_display(agent)).to eq(%w[unknown waiting seen])
    end
  end
end
