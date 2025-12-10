def login_via_6_digit_code(email)
  fill_in("user_email", with: email)
  click_button("Se connecter")
  fill_in("Code à 6 chiffres", with: UserLoginCode.code_for(email))
  click_on "Valider"
end
