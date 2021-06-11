# frozen_string_literal: true

class Admin::ReferentsController < AgentAuthController
  def new
    @user = policy_scope(User).find(params[:user_id])
    authorize(@user)
    @available_agents = policy_scope(Agent).available_referents_for(@user)
  end

  def create
    user = policy_scope(User).find(params[:user_id])
    authorize(user)
    agent = policy_scope(Agent).find(params[:agent_id])
    user.agents << agent
    if user.save
      redirect_to admin_organisation_user_path(current_organisation, user)
    else
      flash.now[:error] = user.errors.full_messages.join(", ")
      render :new
    end
  end

  def update
    user = policy_scope(User).find(params[:user_id])
    authorize(user)
    # TODO: impossible d'utiliser la policy(Agent) ici : il y a des agents de plusieurs services dans les referents.
    agents = current_organisation.agents.where(id: params[:user][:agent_ids])
    flash[:error] = "Erreur lors de la modification des référents" unless user.update(agents: agents)
    redirect_to admin_organisation_user_path(current_organisation, user)
  end
end
