describe CancelRdvByAgentService, type: :service do
  describe "#perform" do
    let(:rdv) { create(:rdv) }

    subject { CancelRdvByAgentService.new(rdv).perform }

    it "changes status to excused" do
      expect { subject }.to change(rdv, :status).from("unknown").to("excused")
    end

    it "sets cancelled_at to now" do
      expect { subject }.to change(rdv, :cancelled_at).from(nil).to(be_within(5.seconds).of(Time.now))
    end

    it "calls notification service" do
      expect(Notifications::Rdv::RdvCancelledByAgentService).to receive(:perform_with)
        .with(rdv)
      subject
    end
  end
end
