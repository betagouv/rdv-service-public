class Admin::UserInWaitingRoomsController < AgentAuthController
  respond_to :turbo_stream

  def create
    rdv = Rdv.find(params[:rdv_id])
    authorize(rdv, policy_class: Agent::RdvPolicy)

    rdv.set_user_in_waiting_room!

    if current_organisation.territory.enable_waiting_room_mail_field
      rdv.agents.select(&:email?).map do |agent|
        Agents::WaitingRoomMailer.with(agent: agent, rdv: rdv).user_in_waiting_room.deliver_later
      end
    end

    render locals: { rdv: }
  end
end
