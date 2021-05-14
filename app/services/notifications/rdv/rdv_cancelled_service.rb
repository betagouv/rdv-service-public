# frozen_string_literal: true

class Notifications::Rdv::RdvCancelledService < ::BaseService
  include Notifications::Rdv::BaseServiceConcern

  protected

  def notify_agent(agent)
    return false if \
      change_triggered_by?(agent) ||
      [Date.today, Date.tomorrow].exclude?(@rdv.starts_at.to_date)

    Agents::RdvMailer
      .rdv_starting_soon_cancelled(@rdv, agent, change_triggered_by_str)
      .deliver_later
  end
end
