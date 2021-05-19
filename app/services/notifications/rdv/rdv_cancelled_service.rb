# frozen_string_literal: true

class Notifications::Rdv::RdvCancelledService < ::BaseService
  include Notifications::Rdv::BaseServiceConcern

  protected

  def notify_agent(agent)
    Agents::RdvMailer
      .rdv_starting_soon_cancelled(@rdv, agent, change_triggered_by_str)
      .deliver_later
  end
end
