# frozen_string_literal: true

class Api::V1::GroupsController < Api::V1::BaseController
  def index
    render_collection(Territory, root: :groups, blueprint_klass: GroupBlueprint)
  end
end
