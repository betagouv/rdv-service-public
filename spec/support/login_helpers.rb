def login_via_6_digit_code(user)
  user = User.find_by!(email: user) if user.is_a?(String)
  fill_in "Prénom", with: user.first_name
  fill_in "Nom", with: user.last_name
  fill_in "Adresse email", with: user.email
  click_button "Recevoir un code de connexion"
  fill_in "Code à 6 chiffres", with: LoginCode.most_recent_usable_for(email: user.email).code
  click_on "Valider"
end
