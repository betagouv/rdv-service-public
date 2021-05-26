# frozen_string_literal: true

describe Users::RegistrationForm, type: :form_model do
  let(:attributes) do
    {
      first_name: "jean",
      last_name: "durand",
      email: "jean@durand.fr"
    }
  end

  describe "validations" do
    it "is valid with complete params" do
      form = described_class.new(attributes)
      expect(form.valid?).to eq(true)
      expect(form.errors).to be_empty
    end

    it "does not allow empty emails" do
      form = described_class.new(attributes.except(:email))
      expect(form.valid?).to eq(false)
      expect(form.errors.keys).to match_array([:email])
    end

    it "also validates user model errors" do
      form = described_class.new(attributes.except(:first_name))
      form.save
      expect(form.errors.keys).to match_array([:first_name])
    end

    it "accessing errors multiple times causes no problem" do
      form = described_class.new(attributes.except(:email, :first_name))
      form.save
      form.save
      expect(form.errors[:first_name].count).to eq 1
      expect(form.errors[:first_name].count).to eq 1
    end
  end
end
