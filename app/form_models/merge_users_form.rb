class MergeUsersForm
  include ActiveModel::Model

  ATTRIBUTES = %i[
    email
    first_name last_name birth_name birth_date phone_number
    address caisse_affiliation affiliation_number family_situation
    number_of_children
    logement notes
  ].freeze

  attr_accessor :user1, :user2, :change_user1_id, :change_user2_id, *ATTRIBUTES

  validates_presence_of :user1, :user2
  validate :different_users?

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
    return %i[first_name last_name birth_date] if user1&.relative? || user2&.relative?

    ATTRIBUTES
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
    ATTRIBUTES
      .select { send(_1) == user_to_merge_number }
      .without(:email) # email cannot be in this list, only to be explicit
  end

  def user1_profile
    user1&.profile_for(@organisation)
  end

  def user2_profile
    user2&.profile_for(@organisation)
  end

  def values_for(attribute)
    if %i[logement notes].include?(attribute)
      [user1_profile&.send(attribute), user2_profile&.send(attribute)]
    else
      [user1&.send(attribute), user2&.send(attribute)]
    end
  end

  def different_users?
    return true if user1.nil? || user2.nil?

    errors.add(:base, "Mauvaise sélection d'usagers") if user1.id == user2.id
  end
end
