class AnnuaireServicePublic
  def initialize(siret)
    @siret = siret
  end

  def mairie?
    return false unless first_result

    JSON.parse(first_result["pivot"]).find do |pivot|
      pivot["type_service_local"] == "mairie"
    end.present?
  rescue StandardError => e
    Sentry.capture_exception(e)
    nil
  end

  def nom
    first_result&.fetch("nom", nil)
  end

  private

  def first_result
    return nil unless @siret
    return nil unless parsed_response
    return nil if parsed_response["total_count"] != 1

    parsed_response["results"].first
  end

  def parsed_response
    @parsed_response ||= JSON.parse(response.body)
  rescue StandardError => e
    Sentry.capture_exception(e)
    nil
  end

  def response
    @response ||= Faraday.get("https://api-lannuaire.service-public.fr/api/explore/v2.1/catalog/datasets/api-lannuaire-administration/records?where=siret%3D%22#{@siret}%22")
  end
end
