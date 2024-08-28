class UserBlueprint < Blueprinter::Base
  identifier :id

  fields  :first_name, :birth_name, :last_name, :email, :address, :phone_number, :phone_number_formatted, :birth_date,
          :responsible_id, :caisse_affiliation, :affiliation_number, :family_situation, :number_of_children, :notify_by_sms,
          :notify_by_email, :invitation_created_at, :invitation_accepted_at, :created_at, :case_number, :address_details,
          :logement, :notes

  association :responsible, blueprint: UserBlueprint

  association :user_profiles, blueprint: UserProfileBlueprint, view: :without_user do |user, options|
    next if options[:agent_context].blank?

    Agent::UserProfilePolicy::Scope.new(options[:agent_context], user.user_profiles).resolve
  end

  view :rdv_insertion do 
    field :organisation_ids 
  end
end
