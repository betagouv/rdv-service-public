module ZammadCustomer
  class Augmenter
    # point d’entrée générique : on ne sait pas si c’est un ticket agent ou usager
    include Rails.application.routes.url_helpers

    attr_reader :zammad_customer

    delegate :email, :phone, to: :zammad_customer

    def initialize(zammad_customer)
      @zammad_customer = zammad_customer
    end

    # rubocop:disable Lint/AssignmentInCondition
    def run
      if agent = Agent.find_by(email:)
        augment_with_agent(agent)
        zammad_customer.note = "Agent trouvé avec l'email #{email}"
      elsif user = User.find_by(email:)
        augment_with_user(user)
        zammad_customer.note = "Usager trouvé avec l'email #{email}"
      elsif matches_by_phone_number_formatted.count > 1
        zammad_customer.note = "Plusieurs usagers trouvés avec le numéro de téléphone formatté #{phone_number_formatted}"
      elsif user = matches_by_phone_number_formatted.first
        augment_with_user(user)
        zammad_customer.note = "Usager trouvé avec le numéro de téléphone formatté #{phone_number_formatted}"
      elsif matches_by_phone_number_raw.count > 1
        zammad_customer.note = "Plusieurs usagers trouvés avec le numéro de téléphone #{phone}"
      elsif user = matches_by_phone_number_raw.first
        augment_with_user(user)
        zammad_customer.note = "Usager trouvé avec le numéro de téléphone #{phone_number}"
      else
        zammad_customer.note = "Aucun usager ni agent trouvé"
      end
    end
    # rubocop:enable Lint/AssignmentInCondition

    def host = ::Domain.default_domain_for_current_instance.host_name

    def augment_with_agent(agent)
      zammad_customer.super_admin_url = super_admins_agent_url(id: agent.id, host:)
      zammad_customer.rdvsp_role = "agent"
    end

    def augment_with_user(user)
      zammad_customer.super_admin_url = super_admins_user_url(id: user.id, host:)
      zammad_customer.rdvsp_role = "user"
    end

    def phone_number_formatted
      @phone_number_formatted ||= PhoneNumberValidation.parsed_number(phone)&.e164
    end

    def matches_by_phone_number_formatted
      phone_number_formatted.present? ? User.where(phone_number_formatted:) : []
    end

    def matches_by_phone_number_raw
      phone.present? && phone.length > 6 ? User.where(phone_number: phone) : []
    end
  end
end
