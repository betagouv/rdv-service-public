# frozen_string_literal: true

class Agents::PasswordsController < Devise::PasswordsController
  respond_to :html, :json

  def create
    agent = Agent.find_by(email: resource_params[:email])
    if agent && !agent.complete?
      if agent.invitation_sent_at
        agent.invite!
        flash[:notice] = "Vous n'avez pas activé votre compte, un email vous a été envoyé."
      else
        flash[:notice] = "Votre compte n'a pas encore été activé, un email vous sera envoyé lorsque cela sera le cas."
      end
      redirect_to root_path
    else
      super
    end
  end
end
