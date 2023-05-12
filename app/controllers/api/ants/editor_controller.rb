# frozen_string_literal: true

class Api::Ants::EditorController < Api::Ants::BaseController
  def get_managed_meeting_points # rubocop:disable Naming/AccessorMethodName
    render json: [].to_json
  end

  def available_time_slots
    render json: params[:meeting_point_ids].map do |meeting_point_id|
      [
        meeting_point_id, [],
      ]
    end.to_hash.to_json
  end
end
