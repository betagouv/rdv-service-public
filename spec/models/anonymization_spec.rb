# frozen_string_literal: true

RSpec.describe "Anonymization" do
  it "lists all the columns that need to be anonymized" do
    anonymized_classes = [User, Receipt]

    anonymized_classes.each do |klass|
      expect(klass.anonymized_column_names + klass.non_anonymized_column_names).to match_array(klass.columns.map(&:name))
    end
  end
end
