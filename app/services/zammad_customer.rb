class ZammadCustomer
  class Attributes
    include ActiveModel::Model
    include ActiveModel::Attributes

    %i[email firstname lastname phone super_admin_url note rdvsp_role].each do |att|
      attribute att, :string
    end

    attribute :instance, :string, default: Domain.default_domain_for_current_instance.to_s

    def augment_with(augmenter)
      augmenter.augment(self)
    end

    def find_user_or_agent_and_augment
      # point d’entrée générique : on ne sait pas si c’est un ticket agent ou usager
      match_details = nil
      [[UserMatcher, UserAugmenter], [AgentMatcher, AgentAugmenter]].each do |matcher_class, augmenter_class|
        matcher = matcher_class.new(self)
        matcher.find_record
        next unless matcher.matched?

        augment_with(augmenter_class.new(matcher.record)) if matcher.record.present?
        match_details = matcher.details
        break
      end
      self.note = match_details || "Aucun usager ni agent trouvé"
    end

    def to_h = attributes
  end

  module MatcherConcern
    # Les Matchers cherchent un User ou un Agent dans notre db sur base de l’email et/ou du numéro de tél

    extend ActiveSupport::Concern

    included do
      attr_reader :customer_attributes, :record, :details

      delegate :email, :phone, to: :customer_attributes
      alias_method :phone_number, :phone
    end

    def initialize(customer_attributes)
      @customer_attributes = customer_attributes
    end

    def matched? = record.present? || details.present? # ça arrive lorsqu’il y a plusieurs matches ambigus
  end

  class AgentMatcher
    include MatcherConcern

    def find_record
      return if customer_attributes.email.blank?

      @record = Agent.find_by(email:)
      @details = "Agent trouvé avec l'email #{email}" if @record.present?
    end
  end

  class UserMatcher
    include MatcherConcern

    def find_record
      match_by_email
      match_by_phone_number if @record.nil?
    end

    private

    def match_by_email
      return nil if email.blank?

      @record = User.find_by(email:)
      @details = "Usager trouvé avec l'email #{email}" if @record.present?
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
        @details = "Plusieurs usagers trouvés avec le numéro de téléphone formatté #{phone_number_formatted}"
        return
      end
      @record = records.first
      if @record.present?
        @details = "Usager trouvé avec le numéro de téléphone formatté #{phone_number_formatted}"
      end
    end

    def match_by_phone_number_raw
      records = User.where(phone_number:)
      if records.count > 1
        @details = "Plusieurs usagers trouvés avec le numéro de téléphone #{phone_number}"
        return
      end
      @record = records.first
      if @record.present?
        @details = "Usager trouvé avec le numéro de téléphone #{phone_number}"
      end
    end

    def phone_number_formatted
      @phone_number_formatted ||= PhoneNumberValidation.parsed_number(phone_number)&.e164
    end
  end

  class AgentAugmenter
    include Rails.application.routes.url_helpers
    def initialize(agent)
      @agent = agent
    end

    def augment(customer_attributes)
      customer_attributes.super_admin_url = super_admins_agent_url(id: @agent.id, host: Domain.default_domain_for_current_instance.host_name)
      customer_attributes.rdvsp_role = "agent"
    end
  end

  class UserAugmenter
    include Rails.application.routes.url_helpers
    def initialize(user)
      @user = user
    end

    def augment(customer_attributes)
      customer_attributes.super_admin_url = super_admins_user_url(id: @user.id, host: Domain.default_domain_for_current_instance.host_name)
      customer_attributes.rdvsp_role = "user"
    end
  end
end
