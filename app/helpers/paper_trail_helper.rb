# frozen_string_literal: true

module PaperTrailHelper
  def paper_trail_change_value(property_name, value)
    return "N/A" if value.nil?
    return I18n.l(value, format: :dense) if value.is_a? Time

    if respond_to?(property_name)
      send(property_name, value)
    else
      value.to_s
    end
  end

  def user_ids(value) # Unused ?
    ::User.where(id: value).order_by_last_name.map(&:full_name).join(", ")
  end

  def status(value) # Unused ?
    ::Rdv.human_enum_name("status", value)
  end

  def agent_ids(value) # Unused ?
    ::Agent.where(id: value).order_by_last_name.map(&:full_name).join(", ")
  end

  def lieu_id(value) # Unused ?
    ::Lieu.find_by(id: value)&.full_name
  end
end
