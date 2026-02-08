class Users::EditForm
  include Users::UserFormConcern

  def initialize(user:, domain:)
    @user = user
    @domain = domain
  end
end
