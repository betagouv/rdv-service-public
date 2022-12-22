# frozen_string_literal: true

class Agents::WaitingRoomMailerPreview < ActionMailer::Preview
  def user_in_waiting_room
    rdv = Rdv.last
    Agents::WaitingRoomMailer.with(agent: rdv.agents.first, rdv: rdv).user_in_waiting_room
  end
end
