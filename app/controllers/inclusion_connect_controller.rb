# frozen_string_literal: true

require "net/http"

class InclusionConnectController < ApplicationController
  def auth
    session[:ic_state] = Digest::SHA1.hexdigest("InclusionConnect - #{SecureRandom.hex(13)}")
    auth_url = "#{ENV['INCLUSION_CONNECT_BASE_URL']}/auth"
    auth_query = {
      response_type: "code",
      client_id: ENV["INCLUSION_CONNECT_CLIENT_ID"],
      redirect_uri: inclusion_connect_callback_url,
      scope: "openid email",
      state: session[:ic_state],
      nonce: Digest::SHA1.hexdigest("Something to check when it come back ?"),
      from: "community",
    }
    auth_path = "#{auth_url}?#{auth_query.to_query}".to_s
    redirect_to auth_path
  end

  def callback
    if params[:state] != session[:ic_state] 
      flash[:error] = "Nous n'avons pas pu vous authentifier. Contacter le support à l'adresse <support@rdv-solidarites.fr> si le problème persiste."
      redirect_to new_agent_session_path and return
    end

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

    if res.is_a?(Net::HTTPSuccess)
      res_body = JSON.parse(res.body)
      token = res_body["access_token"]
      if token.blank?
        flash[:error] = "Nous n'avons pas pu vous authentifier. Contacter le support à l'adresse <support@rdv-solidarites.fr> si le problème persiste."
        redirect_to new_agent_session_path and return
      end
    else
      flash[:error] = "Nous n'avons pas pu vous authentifier. Contacter le support à l'adresse <support@rdv-solidarites.fr> si le problème persiste."
      redirect_to new_agent_session_path and return
    end

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

    unless res.is_a?(Net::HTTPSuccess)
      flash[:error] = "Nous n'avons pas pu vous authentifier. Contacter le support à l'adresse <support@rdv-solidarites.fr> si le problème persiste."
      redirect_to new_agent_session_path and return
    end

    body = JSON.parse(res.body)

    unless body["email_verified"]
      flash[:error] = "Nous n'avons pas pu vous authentifier. Contacter le support à l'adresse <support@rdv-solidarites.fr> si le problème persiste."
      redirect_to new_agent_session_path and return
    end

    email = body["email"]
    agent = Agent.find_by(email: email)

    agent.update(first_name: body["given_name"], last_name: body["family_name"], confirmed_at: Time.zone.now)

    if agent
      bypass_sign_in agent, scope: :agent
      session[:connected_with_inclusionconnect] = true
    else
      flash[:error] = "Nous n'avons pas trouvé d'affectation pour votre email de connexion, veuillez nous contacter par email support@rdv-solidarites.fr"
    end
    redirect_to root_path
  end
end
