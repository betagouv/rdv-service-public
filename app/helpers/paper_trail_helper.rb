# frozen_string_literal: true

module PaperTrailHelper
  def paper_trail_change_value(property_name, value)
    return "N/A" if value.nil?
    return I18n.l(value, format: :dense) if value.is_a? Time

    property_helper = "paper_trail__#{property_name}"
    if respond_to?(property_helper, true)
      send(property_helper, value)
    else
      value.to_s
    end
  end

  private

  def paper_trail__user_ids(value)
    ::User.where(id: value).order_by_last_name.map(&:full_name).join(", ")
  end

  def paper_trail__status(value)
    ::Rdv.human_enum_name("status", value)
  end

  def paper_trail__agent_ids(value)
    ::Agent.where(id: value).order_by_last_name.map(&:full_name).join(", ")
  end

  def paper_trail__lieu_id(value)
    ::Lieu.find_by(id: value)&.full_name
  end

  def paper_trail__service_id(value)
    ::Service.find_by(id: value)&.name
  end
end
