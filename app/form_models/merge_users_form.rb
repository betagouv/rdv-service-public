class MergeUsersForm
  include ActiveModel::Model

  ATTRIBUTES = %i[
    email
    first_name last_name birth_name birth_date phone_number responsible_id
    address
  ].freeze

  attr_accessor :user1, :user2, :change_user1_id, :change_user2_id, *ATTRIBUTES, *Territory::OPTIONAL_FIELD_TOGGLES.values

  validates_presence_of :user1, :user2
  validate :different_users?
  validate :dont_destroy_franceconnected_values

  def initialize(organisation, **kwargs)
    @organisation = organisation
    super(**kwargs)
  end

  def user1_id
    user1&.id
  end

  def user2_id
    user2&.id
  end

  def save
    return false unless valid?

    MergeUsersService.perform_with(user_target, user_to_merge, attributes_to_merge, @organisation)
  end

  def available_attributes
    return %i[first_name last_name birth_date responsible_id] if user1&.relative? || user2&.relative?

    ATTRIBUTES + optional_attributes
  end

  def attribute_comparison(attribute)
    return nil if user1.nil? || user2.nil?

    value1, value2 = values_for(attribute)
    return :identical_na if value1.blank? && value2.blank?

    return :identical if value1 == value2

    :different
  end

  def user_target
    number_to_user(user_target_number)
  end

  protected

  def optional_attributes
    Territory::OPTIONAL_FIELD_TOGGLES.map do |toggle, field_name|
      if @organisation.territory.attributes[toggle.to_s]
        field_name
      end
    end.compact
  end

  def number_to_user(number)
    { "1" => user1, "2" => user2 }[number]
  end

  def user_target_number
    if user2.relative?
      "1"
    elsif user1.relative? && user2.responsible?
      "2"
    else
      email || "1"
    end
  end

  def user_to_merge_number
    { "1" => "2", "2" => "1" }[user_target_number]
  end

  def user_to_merge
    number_to_user(user_to_merge_number)
  end

  def attributes_to_merge
    (ATTRIBUTES + Territory::OPTIONAL_FIELD_TOGGLES.values)
      .select { send(_1) == user_to_merge_number }
      .without(:email) # email cannot be in this list, only to be explicit
  end

  def values_for(attribute)
    [user1&.send(attribute), user2&.send(attribute)]
  end

  def different_users?
    return true if user1.nil? || user2.nil?

    errors.add(:base, "Mauvaise sélection d'usagers") if user1.id == user2.id
  end

  def dont_destroy_franceconnected_values
    return true if user1.nil? || user2.nil?

    User::FranceconnectFrozenFieldsConcern::FROZEN_FIELDS.each do |frozen_field|
      if frozen_field_update?(frozen_field, user1, user2)
        errors.add(frozen_field, "ne peut être modifié.e car un des usagers utilise FranceConnect")
      end
    end
  end

  def frozen_field_update?(frozen_field, user1, user2)
    return false if send(frozen_field).blank?

    selected_value = number_to_user(send(frozen_field)).send(frozen_field)
    (user1.logged_once_with_franceconnect? && selected_value != user1.send(frozen_field)) ||
      (user2.logged_once_with_franceconnect? && selected_value != user2.send(frozen_field))
  end
end
