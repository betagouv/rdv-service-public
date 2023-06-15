# frozen_string_literal: true

module ApiSpecHelper
  def api_auth_headers_for_agent(agent)
    # inspired by https://devise-token-auth.gitbook.io/devise-token-auth/usage/testing
    agent_with_token_auth = AgentWithTokenAuth.find(agent.id)
    token = DeviseTokenAuth::TokenFactory.create
    agent_with_token_auth.tokens[token.client] = { token: token.token_hash, expiry: token.expiry }
    save_without_validating_roles(agent_with_token_auth)
    agent_with_token_auth.build_auth_header(token.token, token.client)
  end

  def parsed_response_body
    JSON.parse(response.body).with_indifferent_access
  end

  def save_without_validating_roles(agent)
    # organisation_have_at_least_one_admin validation on AgentRole model
    # is causing agents not saving if  agent's organisation has no admin
    agent.roles.each do |role|
      role.save(validate: false)
    end
    agent.save!
  end
end
