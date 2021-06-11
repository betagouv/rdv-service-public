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
      redirect_to admin_organisation_user_path(current_organisation, user, anchor: "agents-referents")
    else
      flash.now[:error] = user.errors.full_messages.join(", ")
      render :new
    end
  end

  def destroy
    user = policy_scope(User).find(params[:user_id])
    authorize(user)
    agent = policy_scope(Agent).find(params[:agent_id])
    user.agents.delete(agent)
    if user.save
      redirect_to admin_organisation_user_path(current_organisation, user, anchor: "agents-referents")
    else
      redirect_to admin_organisation_user_path(current_organisation, user, anchor: "agents-referents"), flash: { error: user.errors.full_messages.join(", ") }
    end
  end
end
