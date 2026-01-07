module Users
  class DemandeLoginCodeForm
    include ActiveModel::Model

    attr_reader :login_code

    delegate :email, to: :login_code

    validate :validate_login_code
    validate :validate_user_exists_or_suggest_agent, if: -> { login_code.valid? }

    def initialize(login_code)
      @login_code = login_code
    end

    def validate_user_exists_or_suggest_agent
      return true if User.where(email:).any?

      error =
        if Agent.exists?(email:)
          <<~ERROR
            Aucun compte usager n’existe pour cet email.
            Si vous souhaitez vous connecter en tant qu’agent, veuillez vous rendre sur
            <a href="#{Rails.application.routes.url_helpers.new_agent_session_path(agent: { email: })}">
              la page de connexion agents
            </a>.
          ERROR
        else
          <<~ERROR
            Aucun compte usager n’existe pour cet email, veuillez
            <a href='#{Rails.application.routes.url_helpers.new_user_registration_path(user: { email: })}'>
              créer un compte
            </a>
          ERROR
        end
      errors.add(:base, error.html_safe) # rubocop:disable Rails/OutputSafety
    end

    def validate_login_code
      errors.merge!(login_code) if login_code.invalid?
    end

    def save = valid? && login_code.save
  end
end
