# frozen_string_literal: true

describe SendExportJob, type: :job do
  describe "#perform" do
    it "calls send_notifications" do
      agent = create(:agent, organisations: [create(:organisation)])
      allow(Agents::ExportMailer).to receive(:rdv_export).and_return(instance_double(ActionMailer::MessageDelivery, deliver_later: nil))

      params = {}
      described_class.perform_now(agent.id, agent.organisations.first.id, params)
    end

    it "calls RdvExporter.export to build export" do
      agent = create(:agent, organisations: [create(:organisation)])
      params = {}
      expect(RdvExporter).to receive(:export)
      described_class.perform_now(agent.id, agent.organisations.first.id, params)
    end
  end
end
