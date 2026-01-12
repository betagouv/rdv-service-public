def login_via_6_digit_code(email)
  fill_in "Adresse email", with: email
  click_button "Recevoir un code de connexion"
  fill_in "Code à 6 chiffres", with: LoginCode.most_recent_usable_for(email:).code
  click_on "Valider"
end
