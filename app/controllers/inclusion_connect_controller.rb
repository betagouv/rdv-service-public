# frozen_string_literal: true

require "net/http"

class InclusionConnectController < ApplicationController
  def auth
    auth_url = "#{ENV['INCLUSION_CONNECT_BASE_URL']}/auth"
    auth_query = {
      response_type: "code",
      client_id: ENV["INCLUSION_CONNECT_CLIENT_ID"],
      redirect_uri: inclusion_connect_callback_url,
      scope: "openid email",
      state: Digest::SHA1.hexdigest("un state qui doit changer ?"),
      nonce: Digest::SHA1.hexdigest("Something to check when it come back ?"),
      from: "community",
    }
    auth_path = "#{auth_url}?#{auth_query.to_query}".to_s
    redirect_to auth_path
  end

  def callback
    # TODO: manage errors
    # TODO check state & session-state

    token_url = "#{ENV['INCLUSION_CONNECT_BASE_URL']}/token"
    data = {
      client_id: ENV["INCLUSION_CONNECT_CLIENT_ID"],
      client_secret: ENV["INCLUSION_CONNECT_CLIENT_SECRET"],
      code: params["code"],
      grant_type: "authorization_code",
      redirect_uri: inclusion_connect_callback_url,
    }

    uri = URI(token_url)

    res = Net::HTTP.post_form(uri, data)
    res_body = JSON.parse(res.body) if res.is_a?(Net::HTTPSuccess)

    # TODO: gestion du cas où il y a un problème ou pas de token

    token = res_body["access_token"]
    expires_in = res_body["expires_in"]
    scopes = res_body["scopes"]

    #
    # UserINFO
    #

    userinfo_url = "#{ENV['INCLUSION_CONNECT_BASE_URL']}/userinfo"
    data = { schema: "openid" }

    uri = URI(userinfo_url)
    uri.query = URI.encode_www_form(data)

    req = Net::HTTP::Get.new(uri)
    req["Authorization"] = "Bearer #{token}"

    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
      http.request(req)
    end

    body = JSON.parse(res.body)

    Rails.logger.debug { "body : #{body.inspect}" }
    email = body["email"]
    agent = Agent.find_by(email: email)
    # TODO: Check if email is verified
    # email_verified = body["email_verified"]

    agent.update(first_name: body["given_name"], last_name: body["family_name"], confirmed_at: Time.zone.now)

    if agent
      bypass_sign_in agent, scope: :agent
      session[:connected_with_inclusionconnect] = true
    else
      # TODO: faire un lien clickable
      flash[:error] = "Nous n'avons pas trouvé d'affectation pour votre email de connexion, veuillez nous contacter par email support@rdv-solidarites.fr"
    end
    redirect_to root_path
  end
end
