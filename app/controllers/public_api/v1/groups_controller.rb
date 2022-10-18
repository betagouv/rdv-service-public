# frozen_string_literal: true

class PublicApi::V1::GroupsController < PublicApi::V1::BaseController
  def index
    render_collection(Territory, root: :groups, blueprint_klass: GroupBlueprint)
  end
end
