module ZammadCustomer
  module Matchers
    class UserMatcher
      attr_reader :customer_attributes, :user, :details, :multiple_matches

      delegate :email, :phone, to: :customer_attributes
      alias phone_number phone

      def initialize(customer_attributes)
        @customer_attributes = customer_attributes
      end

      def find_user
        match_by_email
        match_by_phone_number if @user.nil?
        @user
      end

      private

      def match_by_email
        return nil if email.blank?

        @user = User.find_by(email:)
        @details = "Usager trouvé avec l'email #{email}" if @user.present?
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
          @multiple_matches = true
          return
        end
        @user = records.first
        if @user.present?
          @details = "Usager trouvé avec le numéro de téléphone formatté #{phone_number_formatted}"
        end
      end

      def match_by_phone_number_raw
        records = User.where(phone_number:)
        if records.count > 1
          @details = "Plusieurs usagers trouvés avec le numéro de téléphone #{phone_number}"
          @multiple_matches = true
          return
        end
        @user = records.first
        if @user.present?
          @details = "Usager trouvé avec le numéro de téléphone #{phone_number}"
        end
      end

      def phone_number_formatted
        @phone_number_formatted ||= PhoneNumberValidation.parsed_number(phone_number)&.e164
      end
    end
  end
end
