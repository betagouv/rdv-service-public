# frozen_string_literal: true

class Api::V2::OrganizationsController < Api::V2::BaseController
  def index
    render_collection(scope, blueprint_klass: OrganizationBlueprint)
  end

  private

  def scope
    if params[:group_id].present?
      Organisation.where(territory_id: params[:group_id])
    else
      Organisation
    end
  end
end
