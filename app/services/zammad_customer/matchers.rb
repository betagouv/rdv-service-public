module ZammadCustomer
  module Matchers
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
  end
end
