# frozen_string_literal: true

class Notifications::Rdv::RdvCancelledService < ::BaseService
  include Notifications::Rdv::BaseServiceConcern

  protected

  def notify_agent(agent)
    Agents::RdvMailer.rdv_cancelled(@rdv, agent, @author).deliver_later
  end
end
