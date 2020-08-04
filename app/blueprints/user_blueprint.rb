class UserBlueprint < Blueprinter::Base
  identifier :id

  fields :first_name, :last_name, :email, :address, :birth_date, :phone_number
  association :responsible, blueprint: UserBlueprint
end
