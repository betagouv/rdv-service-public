Anonymizer.anonymize_all_data!

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
