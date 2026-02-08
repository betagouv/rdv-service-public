class Users::EditForm
  include Users::UserFormConcern

  def initialize(user:, domain:)
    @user = user
    @domain = domain
  end

  def show_birth_date_field? = false

  def show_ants_pre_demande_number_field? = false
end
