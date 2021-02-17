class UserProfileBlueprint < Blueprinter::Base
  # identifier :id

  fields :logement, :notes

  association :user, blueprint: UserBlueprint
  association :organisation, blueprint: OrganisationBlueprint
end
