class CancelRdvByAgentService
  def initialize(rdv)
    @rdv = rdv
  end

  def perform
    @rdv.update!(status: :excused, cancelled_at: Time.now)
    @rdv.users.map(&:user_to_notify).uniq.each do |user|
      RdvMailer.cancel_by_agent(@rdv, user).deliver_later if user.email.present?
      TwilioSenderJob.perform_later(:rdv_cancelled, @rdv, user) if user.formatted_phone
    end
  end
end
