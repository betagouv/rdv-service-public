# frozen_string_literal: true

class Admin::TerritoriesController < ApplicationController
  include Admin::AuthenticatedControllerConcern

  layout "application_agent_departement"

  before_action :set_territory

  def update
    authorize_admin(@territory)
    flash[:success] = "Mise à jour réussie !" if @territory.update(territory_params)
    render "admin/territories/agent_territorial_roles/index"
  end

  def current_territory
    @territory
  end
  helper_method :current_territory

  def pundit_user
    AgentContext.new(current_agent)
  end

  private

  def set_territory
    @territory = Territory.find(params[:id])
  end

  def territory_params
    params.require(:territory).permit(:name, :phone_number)
  end
end
