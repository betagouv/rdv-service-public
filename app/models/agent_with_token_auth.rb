class AgentWithTokenAuth < Agent
  self.table_name = "agents"
  include DeviseTokenAuth::Concerns::User

  # Authentification dépréciée, réservée aux agents listés dans cette variable d'env (emails séparés par des points-virgules)
  def self.allowed_emails
    ENV["AUTHORIZE_DEPRECATED_API_AUTH_FOR_EMAILS"].to_s.split(";").map { it.strip.downcase }.compact_blank
  end

  # Utilisée par devise_token_auth pour la connexion et pour la vérification des tokens :
  # un agent hors liste est traité comme un agent inexistant
  def self.dta_find_by(attrs = {})
    agent = super
    agent if agent&.email.to_s.downcase.in?(allowed_emails)
  end
end
