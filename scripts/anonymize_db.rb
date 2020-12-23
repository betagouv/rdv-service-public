User.all.each do |u|
  u.update!(
    first_name: Faker::Name.first_name,
    last_name: Faker::Name.last_name,
    phone_number: u.phone_number.present? ? Faker::Base.numerify("06 ## ## ## ##") : nil,
    affiliation_number: u.affiliation_number.present? ? Faker::Base.numerify("############") : nil,
    address: Faker::Address.street_address
  )
end
