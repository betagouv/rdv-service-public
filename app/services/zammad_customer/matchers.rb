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
        match_by_phone_number if @user.nil?
        @user
      end

      private

      def match_by_phone_number
        return nil if phone_number.blank? || phone_number.length < 6

        match_by_phone_number_raw
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
