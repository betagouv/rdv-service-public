require "administrate/field/base"

class EnumField < Administrate::Field::Base
  def to_s
    resource.class.human_enum_name(:role, data)
  end

  def select_field_values(form_builder)
    form_builder.object.class.human_enum_collection(:role)
  end
  
end