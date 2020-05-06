class Notifications::Rdv::RdvCreatedService < ::BaseService
  include Notifications::Rdv::BaseServiceConcern

  protected

  def notify_user(user)
    Users::RdvMailer.rdv_created(@rdv, user).deliver_later if user.email.present?
    TwilioSenderJob.perform_later(:rdv_created, @rdv, user) if user.formatted_phone
  end

  def notify_agent(agent)
    return false unless [Date.today, Date.tomorrow].include?(@rdv.starts_at.to_date)

    Agents::RdvMailer.rdv_starting_soon_created(@rdv, agent).deliver_later
  end
end
