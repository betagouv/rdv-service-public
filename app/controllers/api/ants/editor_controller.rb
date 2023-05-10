# frozen_string_literal: true

class Api::Ants::EditorController < Api::Ants::BaseController
  def get_managed_meeting_points # rubocop:disable Naming/AccessorMethodName
    render json: [].to_json
  end
end
