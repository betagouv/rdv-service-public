class ApplicationMailer < ActionMailer::Base
  default from: "contact@rdv-solidarites.fr"
  append_view_path Rails.root.join("app", "views", "mailers")
  layout "mailer"
end
