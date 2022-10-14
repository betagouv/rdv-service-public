# frozen_string_literal: true

class Api::V1::RdvsController < Api::V1::BaseController

  api :GET, '/api/v1/organisations/:organisation_id/rdvs'
  param :id, :number
  param :organisation_id, :number, desc: 'id of the requested organisation'
  param :name, String
  param :status, [:agent, :user, :file_attente]
  formats ['json', 'jsonp', 'xml']
  def index
    rdvs = policy_scope(Rdv)
    render_collection(rdvs)
  end
end
