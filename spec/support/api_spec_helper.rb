# frozen_string_literal: true

module ApiSpecHelper
  def api_auth_headers_for_agent(agent)
    # inspired by https://devise-token-auth.gitbook.io/devise-token-auth/usage/testing
    agent_with_token_auth = AgentWithTokenAuth.find(agent.id)
    token = DeviseTokenAuth::TokenFactory.create
    agent_with_token_auth.tokens[token.client] = { token: token.token_hash, expiry: token.expiry }
    agent_with_token_auth.save!
    agent_with_token_auth.build_auth_header(token.token, token.client)
  end

  def parsed_response_body
    parsed_response_body = JSON.parse(response.body)
    case parsed_response_body
    when Hash
      parsed_response_body.with_indifferent_access
    when Array
      parsed_response_body.map(&:with_indifferent_access)
    else
      parsed_response_body
    end
  end
end
