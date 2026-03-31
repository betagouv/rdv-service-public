RSpec.describe CustomDeviseMailer do
  context "when delivery fails" do
    it "retries on exception" do
      described_class.invitation_instructions("invalid_param_to_make_job_crash").deliver_later
      expect(enqueued_jobs.pluck("executions")).to eq([0]) # job not executed yet
      perform_enqueued_jobs
      expect(enqueued_jobs.pluck("executions")).to eq([1]) # job enqueued for retry
    end
  end

  context "for agent" do
    subject(:sent_email) { described_class.reset_password_instructions(agent, "t0k3n") }

    let(:inviter) { create(:agent) }
    let(:agent) { create(:agent, invited_by: inviter, invitation_created_at: Time.zone.now) }

    it "doesn't override the reply-to address" do
      perform_enqueued_jobs
      expect(sent_email.from).to eq [Domain::RDV_SERVICE_PUBLIC.support_email]
      expect(sent_email.reply_to).to be_blank
    end

    context "for an invitation" do
      subject(:sent_email) { described_class.invitation_instructions(agent, "t0k3n") }

      it "sets the reply to as the inviter email so that the inviter can resend the invitation if necessary" do
        # Une meilleure solution serait de permettre à l'agent de renvoyer une invitation en autonomie, et on pourra supprimer ce test quand ça sera implémenté
        perform_enqueued_jobs
        expect(sent_email.reply_to).to eq [inviter.email]
      end
    end
  end
end
