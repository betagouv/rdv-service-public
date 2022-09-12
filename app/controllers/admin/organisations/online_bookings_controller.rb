# frozen_string_literal: true

class Admin::Organisations::OnlineBookingsController < AgentAuthController
  before_action :set_organisation

  def show
    authorize(@organisation)
  end
end
