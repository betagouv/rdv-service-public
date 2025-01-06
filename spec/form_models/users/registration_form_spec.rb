RSpec.describe Users::RegistrationForm, type: :form_model do
  let(:attributes) do
    {
      first_name: "jean",
      last_name: "durand",
      email: "jean@durand.fr",
    }
  end

  describe "validations" do
    it "is valid with complete params" do
      form = described_class.new(attributes)
      expect(form.valid?).to be(true)
      expect(form.errors).to be_empty
    end

    it "does not allow empty emails" do
      form = described_class.new(attributes.except(:email))
      expect(form.valid?).to be(false)
      expect(form.errors.attribute_names).to contain_exactly(:email)
    end

    it "does not allow invalid email with single letter domain name" do
      form = described_class.new(first_name: "Jean", last_name: "Jacques", email: "jean@j.f")
      expect(form.valid?).to be(false)
      expect(form.user.errors.count).to eq 1
      expect(form.user.errors.first.attribute).to eq :email
      expect(form.user.errors.first.type).to eq :invalid
    end

    it "does not allow invalid email that starts with a dot" do
      form = described_class.new(first_name: "Jean", last_name: "Jacques", email: ".jean@jacques.fr")
      expect(form.valid?).to be(false)
      expect(form.user.errors.count).to eq 1
      expect(form.user.errors.first.attribute).to eq :email
      expect(form.user.errors.first.type).to eq :invalid
    end

    it "also validates user model errors" do
      form = described_class.new(attributes.except(:first_name))
      form.save
      expect(form.errors.attribute_names).to contain_exactly(:first_name)
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
