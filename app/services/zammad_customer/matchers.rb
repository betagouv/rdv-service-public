module ZammadCustomer
  module Matchers
    class AgentMatcher
      attr_reader :customer_attributes, :record, :details

      delegate :email, to: :customer_attributes

      def initialize(customer_attributes)
        @customer_attributes = customer_attributes
      end

      def matched? = record.present?

      def find_record
        return if customer_attributes.email.blank?

        @record = Agent.find_by(email:)
        @details = "Agent trouvé avec l'email #{email}" if @record.present?
      end
    end

    class UserMatcher
      attr_reader :customer_attributes, :record, :details

      delegate :email, :phone, to: :customer_attributes
      alias phone_number phone

      def initialize(customer_attributes)
        @customer_attributes = customer_attributes
      end

      def matched? = record.present? || details.present? # ça arrive lorsqu’il y a plusieurs matches ambigus

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
