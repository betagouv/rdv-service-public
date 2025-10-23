module ZammadCustomer
  class Attributes
    include ActiveModel::Model # provides the convenient initializer
    include ActiveModel::Attributes # lets us declare attributes easily

    %i[email firstname lastname phone super_admin_url note rdvsp_role].each do |att|
      attribute att, :string
    end

    attribute :instance, :string, default: Domain.default_domain_for_current_instance.to_s

    def to_h = attributes

    def phone_number_formatted
      @phone_number_formatted ||= PhoneNumberValidation.parsed_number(phone)&.e164
    end
  end
end
