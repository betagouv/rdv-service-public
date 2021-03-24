# rails runner scripts/ics_investigation/send_mail_po.rb

plage_ouverture = PlageOuverture.last
plage_ouverture.organisation = Organisation.first
plage_ouverture.recurrence = nil

plage_ouverture.first_day = Date.new(2021, 4, 5).in_time_zone
plage_ouverture.start_time = Tod::TimeOfDay.new(9)
plage_ouverture.end_time = Tod::TimeOfDay.new(12)
plage_ouverture.title = "Test 11"
recipient_mail = "christelle.cufay@le64.fr"
# recipient_mail = "adrien_test2@outlook.com"

# Agents::PlageOuvertureMailer
#   .plage_ouverture_created(
#     Admin::Ics::PlageOuverture
#       .create_payload(plage_ouverture)
#       .merge(agent_email: recipient_mail)
#   ).deliver_now

Agents::PlageOuvertureMailer.debug_ics(
  Rails.root.join("scripts", "ics_investigation", "test11.ics"),
  recipient_mail,
  plage_ouverture.title
).deliver_now
