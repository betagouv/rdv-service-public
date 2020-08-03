describe Users::RegistrationForm, type: :form_model do
  let(:attributes) do
    {
      first_name: "jean",
      last_name: "durand",
      email: "jean@durand.fr",
      password: "jeanjean",
    }
  end

  describe "validations" do
    it "should be valid with complete params" do
      form = Users::RegistrationForm.new(attributes)
      expect(form.valid?).to eq(true)
      expect(form.errors).to be_empty
    end

    it "should not allow empty emails" do
      form = Users::RegistrationForm.new(attributes.except(:email))
      expect(form.valid?).to eq(false)
      expect(form.errors.keys).to match_array([:email])
    end

    it "should not allow empty password" do
      form = Users::RegistrationForm.new(attributes.except(:password))
      expect(form.valid?).to eq(false)
      expect(form.errors.keys).to match_array([:password])
    end

    it "also validates user model errors" do
      form = Users::RegistrationForm.new(attributes.except(:first_name))
      form.save
      expect(form.errors.keys).to match_array([:first_name])
    end

    it "accessing errors multiple times causes no problem" do
      form = Users::RegistrationForm.new(attributes.except(:email, :first_name))
      form.save
      form.save
      expect(form.errors[:first_name].count).to eq 1
      expect(form.errors[:first_name].count).to eq 1
    end
  end
end
