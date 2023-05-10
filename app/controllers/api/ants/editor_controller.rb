# frozen_string_literal: true

class Api::Ants::EditorController < Api::Ants::BaseController
  def get_managed_meeting_points
    render json: [].to_json
  end
end
