# frozen_string_literal: true

class Api::V1::OrganisationsController < Api::V1::BaseController
  def index
    organisations = policy_scope(Organisation)
    render_collection(organisations.order(:id))
  end
end
