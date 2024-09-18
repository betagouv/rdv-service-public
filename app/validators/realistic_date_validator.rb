class RealisticDateValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?

    if value > 5.years.from_now
      record.errors.add(attribute, "ne peut pas être dans plus de 5 ans")
    end

    if value.year < 2018
      record.errors.add(attribute, "ne peut pas être avant 2018")
    end
  end
end
