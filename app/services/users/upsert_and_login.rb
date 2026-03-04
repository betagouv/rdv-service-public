class Users::UpsertAndLogin
  def initialize(email:, first_name:, last_name:, organisation:)
    @email = email or raise("email required")
    @first_name = first_name
    @last_name = last_name
    @organisation = organisation
  end

  attr_reader :user

  def perform
    ActiveRecord::Base.transaction do
      @user = upsert_user
      user.update!(latest_login_at: Time.zone.now) if user.respond_to?(:latest_login_at)
    end
  end

  def upsert_user
    user = User.find_by(email: @email)
    if user
      update_user(user) if @first_name.present? && @last_name.present?
    else
      user = create_user
    end
    user
  end

  def update_user(user)
    both_names_changed = user.first_name != @first_name || user.last_name != @last_name
    if both_names_changed && !user.connected_with_sso? # les users France/Pro-Connectés ne peuvent pas modifier leur identité
      user.update!(first_name: @first_name, last_name: @last_name)
    end
  end

  def create_user
    User.create!(email: @email, first_name: @first_name, last_name: @last_name, created_through: "auto_through_login")
  end
end
