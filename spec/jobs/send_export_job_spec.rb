# frozen_string_literal: true

describe SendExportJob, type: :job do
  describe "#perform" do
    it "calls export mailer" do
      agent = create(:agent, organisations: [create(:organisation)])
      # rubocop:disable RSpec/StubbedMock
      expect(Agents::ExportMailer).to receive(:rdv_export).and_return(instance_double(ActionMailer::MessageDelivery, deliver_later: nil))
      # rubocop:enable RSpec/StubbedMock

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
