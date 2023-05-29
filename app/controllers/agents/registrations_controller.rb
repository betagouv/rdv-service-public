# frozen_string_literal: true

class Agents::RegistrationsController < Devise::RegistrationsController
  respond_to :html, :json
  before_action :prevent_if_upcoming_rdvs, only: [:destroy]

  def pundit_user
    AgentContext.new(current_agent)
  end

  def destroy
    flash[:notice] = "Votre compte a été supprimé."
    current_agent.organisations.each { AgentRemoval.new(@agent, _1).remove! }
    current_agent.destroy! if current_agent.persisted?
    Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name)
    redirect_to root_path
  end

  private

  def prevent_if_upcoming_rdvs
    org_with_upcoming_rdvs = current_agent.organisations.all.find { AgentRemoval.new(@agent, _1).upcoming_rdvs? }
    return unless org_with_upcoming_rdvs

    flash[:error] =
      "Impossible de supprimer votre compte car vous avez des RDVs à venir dans l'organisation #{org_with_upcoming_rdvs.name}. "\
      "Veuillez les supprimer ou les réaffecter avant de supprimer votre compte."
    redirect_to edit_agent_registration_path
  end

  def after_inactive_sign_up_path_for(_)
    new_agent_session_path
  end

  def after_update_path_for(_)
    edit_agent_registration_path
  end
end
