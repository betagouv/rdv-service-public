# frozen_string_literal: true

class Api::V1::OrganizationsController < Api::V1::BaseController
  def index
    render_collection(scope, root: :organizations, blueprint_klass: OrganizationBlueprint)
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
