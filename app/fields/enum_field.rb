require "administrate/field/base"

class EnumField < Administrate::Field::Base
  delegate :to_s, to: :data

  def select_field_values(form_builder)
    form_builder.object.class.public_send(attribute.to_s.pluralize).keys.map do |v|
      [v.titleize, v]
    end
  end
end
