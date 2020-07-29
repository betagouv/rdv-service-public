module SigninSpecHelper
  def sign_in(user)
    fill_in :user_email, with: user.email
    fill_in :password, with: user.password
    click_on 'Se connecter'
  end
end
