# frozen_string_literal: true

class Api::V1::RdvsController < Api::V1::BaseController
  def index
    rdvs = policy_scope(Rdv)
    render_collection(rdvs)
  end
end
