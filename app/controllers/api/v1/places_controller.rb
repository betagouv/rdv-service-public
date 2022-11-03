# frozen_string_literal: true

class Api::V1::PlacesController < Api::V1::BaseController
  def index
    render_collection(scope, root: :places, blueprint_klass: PlaceBlueprint)
  end

  private

  def scope
    if params[:organization_id].present?
      Lieu.where(organisation_id: params[:organization_id])
    else
      Lieu
    end
  end
end
