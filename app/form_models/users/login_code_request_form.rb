module Users
  class LoginCodeRequestForm
    include ActiveModel::Model

    attr_reader :login_code, :behaviour

    delegate :email, :first_name, :last_name, to: :login_code

    validate :validate_login_code
    validates :behaviour, inclusion: { in: %w[upsert_user find_existing_user].freeze }
    validate :validate_not_sent_too_recently, if: -> { login_code.valid? }
    validates :first_name, :last_name, presence: true, if: -> { login_code.valid? && behaviour == "upsert_user" }
    validate :validate_user_exists_or_suggest_agent, if: -> { login_code.valid? && behaviour == "find_existing_user" }

    def initialize(login_code, behaviour: nil)
      @login_code = login_code
      @behaviour = behaviour.presence || "find_existing_user"
    end

    def validate_login_code
      errors.merge!(login_code) if login_code.invalid?
    end

    def validate_user_exists_or_suggest_agent
      return true if User.loginable_by_code_for_email(email).any?

      error =
        if Agent.exists?(email:)
          <<~ERROR
            Aucun compte usager n’existe pour cet email.
            Si vous souhaitez vous connecter en tant qu’agent, veuillez vous rendre sur la page de connexion agent.
          ERROR
        else
          "Aucun compte usager n’existe pour cet email"
        end
      errors.add(:base, error)
    end

    def validate_not_sent_too_recently
      if LoginCode.most_recent_usable_for(email:)&.very_recent?
        errors.add(:base, <<~ERROR)
          Un code a été envoyé à #{email} il y a moins de deux minutes.
          Vous devriez recevoir ce code d’ici peu de temps.
        ERROR
      end
    end

    def save = valid? && login_code.save
  end
end
