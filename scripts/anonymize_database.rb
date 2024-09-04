if Rails.env.production?
  raise "L'anonymisation en masse est désactivée en production pour éviter les catastrophes"
end

Anonymizer.default_config.table_configs.each do |table_config|
  next unless ActiveRecord::Base.connection.table_exists?(table_config)

  Anonymizer::Table.new(table_config:).anonymize_records!
end

if User.where.not(last_name: "[valeur anonymisée]").any?
  raise "Certains usagers n'ont pas été anonymisés !"
end

if Agent.where.not(last_name: "[valeur anonymisée]").any?
  raise "Certains agents n'ont pas été anonymisés !"
end

if Prescripteur.where.not(first_name: "[valeur anonymisée]").any?
  raise "Certains prescripteurs n'ont pas été anonymisés !"
end

if Receipt.where.not(content: "[valeur anonymisée]").any?
  raise "Certains receipts n'ont pas été anonymisés !"
end
