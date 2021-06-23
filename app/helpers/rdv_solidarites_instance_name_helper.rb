# frozen_string_literal: true

module RdvSolidaritesInstanceNameHelper
  # Display a small indicator that this is not the production website.
  def rdv_solidarites_instance_name
    if ENV["RDV_SOLIDARITES_INSTANCE_NAME"].present?
      ENV["RDV_SOLIDARITES_INSTANCE_NAME"]
    elsif Rails.env.development?
      Rails.env
    end
  end
end
