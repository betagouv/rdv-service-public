class UserProfileBlueprint < Blueprinter::Base
  fields :logement, :notes

  association :user, blueprint: UserBlueprint
  association :organisation, blueprint: OrganisationBlueprint

  view :without_user do
    exclude :user
  end
end
