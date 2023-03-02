# Be sure to restart your server when you modify this file.

# Configure parameters to be filtered from the log file. Use this to limit dissemination of
# sensitive information. See the ActiveSupport::ParameterFilter documentation for supported
# notations and behaviors.
Rails.application.config.filter_parameters += %i[
  password passw secret token _key crypt salt certificate otp ssn api_key notes
  email first_name last_name phone_number phone_number_formatted affiliation_number birth_date
  address city_code post_code city_name address_details logement
  family_situation number_of_children case_number
]

# NOTE: Le logging des paramètres a été désactivé dans
# https://github.com/betagouv/rdv-solidarites.fr/pull/3374
# et donc cette liste de champs n'es plus opérante.
# Nous la laissons pour qu'elle serve de base si l'on
# décide de logger à nouveau les params HTTP.
