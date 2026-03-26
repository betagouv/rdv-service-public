class UserBlueprint < Blueprinter::Base
  identifier :id

  fields  :first_name, :birth_name, :last_name, :email, :address, :phone_number, :phone_number_formatted, :birth_date,
          :responsible_id, :affiliation_number, :notify_by_sms, :notify_by_email, :created_at, :address_details

  association :responsible, blueprint: UserBlueprint

  association :user_profiles, blueprint: UserProfileBlueprint, view: :without_user do |user, options|
    next if options[:agent_context].blank?

    Agent::UserProfilePolicy::Scope.new(options[:agent_context], user.user_profiles).resolve
  end
end
