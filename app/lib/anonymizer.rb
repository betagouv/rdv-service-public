# frozen_string_literal: true

class Anonymizer
  def self.anonymize_all_data!
    anonymize_user_data!
    Prescripteur.anonymize_all!
    Agent.anonymize_all!
  end

  def self.anonymize_user_data!
    User.anonymize_all!
    Receipt.anonymize_all!
    Rdv.anonymize_all!
  end
end
