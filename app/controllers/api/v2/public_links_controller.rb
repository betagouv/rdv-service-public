# frozen_string_literal: true

class Api::V2::PublicLinksController < Api::V1::PublicLinksController
  def index
    # Using cache to prevent overloading db in case of accidentally intensive API calls
    response_body = Rails.cache.fetch("api/v2/public_links/#{@territory.id}", expires_in: 1.minute) do
      { public_links: public_links_for(@territory) }.to_json
    end

    render json: response_body
  end
end
