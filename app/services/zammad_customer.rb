class ZammadCustomer
  def self.user_or_agent_builder(email:, phone_number:)
    # point d’entrée générique : on ne sait pas si c’est un ticket agent ou usager
    user_builder = UserBuilder.new(email:, phone_number:)
    user_builder.match
    return user_builder if user_builder.matched?

    agent_builder = AgentBuilder.new(email:)
    agent_builder.match
    return agent_builder if agent_builder.matched?

    NoMatchBuilder.new
  end

  module BuilderConcern
    extend ActiveSupport::Concern

    included do
      include Rails.application.routes.url_helpers
      attr_reader :email, :note, :record
    end

    def attributes
      {
        instance: domain.to_s,
        super_admin_url:,
        note:,
      }.compact
    end

    def matched? = @record.present? || @note.present?
    def domain = Domain.default_domain_for_current_instance
    def host = domain.host_name
  end

  class AgentBuilder
    include BuilderConcern

    def initialize(email: nil, record: nil)
      @email = email
      @record = record
    end

    def match
      return if @record.present?

      if email.present?
        @record = Agent.find_by(email:)
        if @record.present?
          @note = "Agent trouvé avec l'email #{email}"
          nil
        end
      end
    end

    def super_admin_url
      return if @record.blank?

      super_admins_agent_url(id: @record.id, host:)
    end
  end

  class UserBuilder
    attr_reader :phone_number

    include BuilderConcern

    def initialize(email: nil, phone_number: nil, record: nil)
      @email = email
      @phone_number = phone_number
      @record = record
    end

    def match
      return if @record.present?

      match_by_email
      match_by_phone_number if @record.nil?
    end

    private

    def match_by_email
      return nil if email.blank?

      @record = User.find_by(email:)
      if @record.present?
        @note = "Usager trouvé avec l'email #{email}"
      end
    end

    def match_by_phone_number
      return nil if phone_number.blank? || phone_number.length < 6

      if phone_number_formatted.present?
        match_by_phone_number_formatted
      else
        match_by_phone_number_raw
      end
    end

    def match_by_phone_number_formatted
      records = User.where(phone_number_formatted:)
      if records.count > 1
        @note = "Plusieurs usagers trouvés avec le numéro de téléphone formatté #{phone_number_formatted}"
        return
      end
      @record = records.first
      if @record.present?
        @note = "Usager trouvé avec le numéro de téléphone formatté #{phone_number_formatted}"
      end
    end

    def match_by_phone_number_raw
      records = User.where(phone_number:)
      if records.count > 1
        @note = "Plusieurs usagers trouvés avec le numéro de téléphone #{phone_number}"
        return
      end
      @record = records.first
      if @record.present?
        @note = "Usager trouvé avec le numéro de téléphone #{phone_number}"
      end
    end

    def phone_number_formatted
      @phone_number_formatted ||= PhoneNumberValidation.parsed_number(phone_number)&.e164
    end

    def super_admin_url
      super_admins_user_url(id: record.id, host:) if record.present?
    end
  end

  class NoMatchBuilder
    def attributes = { note: "Aucun usager ni agent trouvé" }
  end
end
