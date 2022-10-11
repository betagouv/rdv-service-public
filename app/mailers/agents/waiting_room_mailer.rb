# frozen_string_literal: true

class Agents::WaitingRoomMailer < ApplicationMailer
  before_action do
    @agent = params[:agent]
    @rdv = params[:rdv]
  end

  default to: -> { @agent.email }

  def user_in_waiting_room
    mail(subject: t("agents.waiting_room_mailer.title", domain_name: domain.name))
  end

  def domain
    @agent.domain
  end
end
