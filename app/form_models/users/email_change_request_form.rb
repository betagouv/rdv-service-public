module Users
  class EmailChangeRequestForm
    include ActiveModel::Model

    attr_reader :email, :current_user, :domain_id

    validate :validate_can_change_email
    validate :validate_login_code
    validate :validate_new_email_different, if: -> { errors[:email].empty? }
    validate :validate_not_sent_too_recently, if: -> { errors[:email].empty? }

    def initialize(current_user:, domain_id:, email: nil)
      @current_user = current_user
      @domain_id = domain_id
      @email = email
    end

    def login_code
      @login_code ||= LoginCode.new(email:, domain_id:)
    end

    def save
      return unless valid?

      return unless login_code.save

      Users::EmailChangeMailer.with(login_code:).confirmation_code.deliver_later
    end

    private

    def validate_can_change_email
      return if current_user.can_change_email?

      errors.add(:base, "Vous ne pouvez pas modifier votre adresse email.")
    end

    def validate_login_code
      errors.merge!(login_code) if login_code.invalid?
    end

    def validate_new_email_different
      return unless email.casecmp?(current_user.email.to_s)

      errors.add(:base, "La nouvelle adresse email doit être différente de l’adresse actuelle")
    end

    def validate_not_sent_too_recently # doublon dans LoginCodeRequestForm
      if LoginCode.most_recent_usable_for(email:)&.very_recent?
        errors.add(:base, <<~ERROR)
          Un code a été envoyé à #{email} il y a moins de deux minutes.
          Vous devriez recevoir ce code d’ici peu de temps.
        ERROR
      end
    end
  end
end
