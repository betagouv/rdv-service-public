module ApiSpecHelper
  def oauth_client_headers(oauth_token)
    {
      "Content-Type": "application/json",
      Authorization: "Bearer #{oauth_token.plaintext_token}",
    }
  end

  def api_auth_headers_for_agent(agent)
    # inspired by https://devise-token-auth.gitbook.io/devise-token-auth/usage/testing
    agent_with_token_auth = AgentWithTokenAuth.find(agent.id)
    token = DeviseTokenAuth::TokenFactory.create
    agent_with_token_auth.tokens[token.client] = { token: token.token_hash, expiry: token.expiry }
    save_without_validating_roles(agent_with_token_auth)
    agent_with_token_auth.build_auth_headers(token.token, token.client)
  end

  def api_auth_headers_with_shared_secret(agent, shared_secret)
    payload = { id: agent.id, first_name: agent.first_name, last_name: agent.last_name, email: agent.email }
    encrypted_payload = OpenSSL::HMAC.hexdigest("SHA256", shared_secret, payload.to_json)
    { uid: agent.email, "X-Agent-Auth-Signature": encrypted_payload }
  end

  def parsed_response_body
    JSON.parse(response.body).with_indifferent_access
  end

  def save_without_validating_roles(agent)
    # organisation_have_at_least_one_admin validation on AgentRole model
    # is causing validation error if agent's organisation has no admin
    AgentRole.skip_callback(:validate, :organisation_have_at_least_one_admin)
    agent.roles.map(&:save)
    AgentRole.set_callback(:validate, :organisation_have_at_least_one_admin)
    agent.save!
  end

  def self.external_id_error_response
    {
      "errors" => { "external_id" => [{ "error" => "taken", "value" => "123ABC" }] },
      "error_messages" => ["external_id est déjà utilisé"],
    }
  end

  def self.invalid_motif_response(organisation_id = 1)
    {
      "error_messages" => ["base Il existe déjà dans Organisation n°#{organisation_id} un motif Sur place nommé \"Suivi de dossier\" ouvert à tous les agents"],
      "errors" => { "base" => [{ "error" => "duplicate_detected" }] },
    }
  end
end
