class Agents::PasswordsController < Devise::PasswordsController
  respond_to :html, :json

  def create
    agent = Agent.find_by(email: resource_params[:email])
    if agent && !agent.complete?
      agent.invite!
      flash[:notice] = "Vous n'avez pas activé votre compte, un email vous a été envoyé."
      redirect_to root_path
    else
      super
    end
  end
end
