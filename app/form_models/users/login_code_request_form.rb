module Users
  class LoginCodeRequestForm
    include ActiveModel::Model

    attr_reader :login_code

    delegate :email, :first_name, :last_name, to: :login_code

    validate :validate_login_code
    validate :validate_not_sent_too_recently, if: -> { login_code.valid? }

    def initialize(login_code)
      @login_code = login_code
    end

    def validate_not_sent_too_recently
      if LoginCode.most_recent_usable_for(email:)&.very_recent?
        errors.add(:base, <<~ERROR.html_safe) # rubocop:disable Rails/OutputSafety
          Un code a été envoyé à #{email} il y a moins de deux minutes.
          Vous devriez recevoir ce code d’ici peu de temps.
          <a href="#{Rails.application.routes.url_helpers.new_users_sessions_by_code_path(email:)}">
            Suivez ce lien pour saisir le code reçu.
          </a>
        ERROR
      end
    end

    def validate_login_code
      errors.merge!(login_code) if login_code.invalid?
    end

    def save = valid? && login_code.save
  end
end
