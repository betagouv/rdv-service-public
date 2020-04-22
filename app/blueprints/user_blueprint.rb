class UserBlueprint < Blueprinter::Base
  identifier :id

  fields :first_name, :last_name, :email, :address, :birth_date
  association :responsible, blueprint: UserBlueprint
end
