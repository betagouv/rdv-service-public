module ApiSpecHelper
  def api_auth_headers_for_agent(agent)
    # inspired by https://devise-token-auth.gitbook.io/devise-token-auth/usage/testing
    token = DeviseTokenAuth::TokenFactory.create
    agent.tokens[token.client] = { token: token.token_hash, expiry: token.expiry }
    agent.save!
    agent.build_auth_header(token.token, token.client)
  end
end
