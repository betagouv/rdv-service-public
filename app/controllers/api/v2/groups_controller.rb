# frozen_string_literal: true

class Api::V2::GroupsController < Api::V2::BaseController
  def index
    render_collection(Territory, blueprint_klass: GroupBlueprint)
  end
end
