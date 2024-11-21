# cf docs/interconnexions/visioplainte.md

class Api::Visioplainte::BaseController < ActionController::Base # rubocop:disable Rails/ApplicationController
  respond_to :json
  skip_forgery_protection # L'authentification par clé d'api nous protège des csfr

  before_action :authenticate_with_api_key

  GENDARMERIE_SERVICE_NAME = "Gendarmerie Nationale".freeze

  def reset
    # On met plusieurs guard clauses de sécurité pour s'assurer qu'on ne peut appeler cette méthode destructive que sur la staging
    return unless ENV["RDV_SOLIDARITES_INSTANCE_NAME"] == "STAGING"
    return unless ENV["VISIOPLAINTE_API_KEY"].start_with?("visioplainte-staging-api-key-")
    return unless ENV["FRANCECONNECT_HOST"] == "fcp.integ01.dev-franceconnect.fr"

    territory = Territory.find_by(name: Territory::VISIOPLAINTE_NAME)

    territory.organisations.find_each do |organisation|
      organisation.plage_ouvertures.delete_all
      organisation.rdvs.destroy_all
      organisation.user_profiles.destroy_all
      organisation.agents.find_each do |a|
        a.rdvs.delete_all
        a.roles.delete_all
        a.destroy!
      end
    end
    territory.destroy! # Ce destroy fera les suppressions restantes en cascade via des dependent: :destroy

    load Rails.root.join("db/seeds/visioplainte.rb")
    head :ok
  end

  protected

  def allow_authentication_with_read_only_api_key
    @read_only_api_key_allowed = true
  end

  def authenticate_with_api_key
    authorized = ActiveSupport::SecurityUtils.secure_compare(
      request.headers["X-VISIOPLAINTE-API-KEY"] || "",
      ENV.fetch("VISIOPLAINTE_API_KEY")
    ) || authorized_with_read_only_api_key?

    unless authorized
      render(
        status: :unauthorized,
        json: {
          errors: ["Authentification invalide"],
        }
      )
    end
  end

  def authorized_with_read_only_api_key?
    return false unless @read_only_api_key_allowed
    return false if ENV["VISIOPLAINTE_API_KEY_READ_ONLY"].blank?

    ActiveSupport::SecurityUtils.secure_compare(
      request.headers["X-VISIOPLAINTE-API-KEY"],
      ENV["VISIOPLAINTE_API_KEY_READ_ONLY"]
    )
  end
end
