class DemoThing
  include HumanAttributeValue

  # #attribute_types and #human_attribute_name are ActiveRecord/ActiveModel methods
  def self.attribute_types
    {
      "some_str" => ActiveModel::Type::String.new,
      "some_bool" => ActiveModel::Type::Boolean.new,
    }
  end

  def self.human_attribute_name(key, _options)
    i18n = {
      "some_strs.value_one" => "My string value",
      "some_strs/specific_context.value_one" => "My string value in context",
      "some_bools.true" => "My bool is true",
      "some_bools.false" => "My bool is false",
    }
    i18n[key]
  end
end

RSpec.describe HumanAttributeValue do
  describe "#human_attribute_value" do
    subject { DemoThing.human_attribute_value(attr_name, value, options) }

    let(:options) { {} }

    context "attribute and value are valid" do
      let(:attr_name) { :some_str }
      let(:value) { "value_one" }

      it { is_expected.to eq "My string value" }
    end

    context "specific context" do
      let(:attr_name) { :some_str }
      let(:value) { "value_one" }
      let(:options) { { context: "specific_context" } }

      it { is_expected.to eq "My string value in context" }
    end

    context "value is unknown" do
      let(:attr_name) { :some_str }
      let(:value) { "unknown_value" }

      it { is_expected.to be_nil }
    end

    context "value is nil" do
      let(:attr_name) { :some_str }
      let(:value) { nil }

      it { is_expected.to be_nil }
    end

    context "string value is empty" do
      let(:attr_name) { :some_str }
      let(:value) { "" }

      it { is_expected.to be_nil }
    end

    context "string value ends with a dot (.)" do
      it "works" do
        user = User.new(notes: "C'est ainsi.")
        expect(user.human_attribute_value(:notes)).to eq("C'est ainsi.")
      end
    end

    context "bool value is true" do
      let(:attr_name) { :some_bool }
      let(:value) { true }

      it { is_expected.to eq "My bool is true" }
    end

    context "bool value is false" do
      let(:attr_name) { :some_bool }
      let(:value) { false }

      it { is_expected.to eq "My bool is false" }
    end
  end
end
