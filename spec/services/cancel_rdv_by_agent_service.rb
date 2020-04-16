describe CancelRdvByAgentService, type: :service do
  describe ".perform" do
    let(:now) { Time.now }
    let(:rdv) { create(:rdv) }

    before do
      travel_to(now)
      freeze_time
    end

    subject { CancelRdvByAgentService.new(rdv).perform }

    it "changes status to excused" do
      expect { subject }.to change(rdv, :status).from("unknown").to("excused")
    end

    it "sets cancelled_at to now" do
      expect { subject }.to change(rdv, :cancelled_at).from(nil).to(Time.now)
    end

    it "calls RdvMailer to send email to user" do
      expect(RdvMailer).to receive(:cancellation).with(rdv, rdv.users.first).and_return(double(deliver_later: nil))
      subject
    end

    it "calls RdvMailer to send email to user" do
      expect(TwilioSenderJob).to receive(:perform_later).with(:rdv_cancelled, rdv, rdv.users.first)
      subject
    end
  end
end
