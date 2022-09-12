# frozen_string_literal: true

class Admin::Organisations::OnlineBookingsController < AgentAuthController
  before_action :set_organisation
  before_action :check_conseiller_numerique

  def show
    authorize(@organisation)
  end

  private

  def check_conseiller_numerique
    redirect_to authenticated_agent_root_path unless current_agent.conseiller_numerique?
  end
end
