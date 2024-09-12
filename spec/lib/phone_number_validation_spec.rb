RSpec.describe PhoneNumberValidation do
  describe "parsed_number" do
    it "prevents malformed numbers" do
      expect(described_class.parsed_number("wrong value")).to be_nil
      expect(described_class.parsed_number("06 12 34 56 7")).to be_nil
      expect(described_class.parsed_number(" +33 6 10 00 00 00 1")).to be_nil
    end

    it "allows fixed line numbers" do
      expect(described_class.parsed_number(" +33 1 23 45 67 89")).not_to be_nil
    end

    it "allows ten-digit DROM numbers" do
      expect(described_class.parsed_number("    06 10 00 00 00")).not_to be_nil # FR
      expect(described_class.parsed_number("    06 90 00 00 00")).not_to be_nil # GP
      expect(described_class.parsed_number("    06 93 00 00 00")).not_to be_nil # RE/YT
      expect(described_class.parsed_number("    06 94 00 00 00")).not_to be_nil # GF
      expect(described_class.parsed_number("    06 96 00 00 00")).not_to be_nil # MQ
    end

    it "allows DROM number with an explicit international prefix" do
      expect(described_class.parsed_number(" +33 6 10 00 00 00")).not_to be_nil # FR
      expect(described_class.parsed_number("+590 6 90 00 00 00")).not_to be_nil # GP
      expect(described_class.parsed_number("+262 6 93 00 00 00")).not_to be_nil # RE/YT
      expect(described_class.parsed_number("+594 6 94 00 00 00")).not_to be_nil # GF
      expect(described_class.parsed_number("+596 6 96 00 00 00")).not_to be_nil # MQ
    end

    it "prevents DROM number with a wrong +33 prefix" do
      expect(described_class.parsed_number(" +33 6 90 00 00 00")).to be_nil
      expect(described_class.parsed_number(" +33 6 93 00 00 00")).to be_nil
      expect(described_class.parsed_number(" +33 6 94 00 00 00")).to be_nil
      expect(described_class.parsed_number(" +33 6 96 00 00 00")).to be_nil
    end

    it "allows international numbers" do
      expect(described_class.parsed_number("+1 2014000000")).not_to be_nil   # USA
      expect(described_class.parsed_number("+212 5222-54321")).not_to be_nil # Maroc
    end
  end

  describe "number_is_mobile?" do
    it do
      expect(described_class.number_is_mobile?(" +33 6 10 00 00 00")).to be(true)
      expect(described_class.number_is_mobile?(" +33 1 23 45 67 89")).to be(false)
      expect(described_class.number_is_mobile?("+596 6 96 00 00 00")).to be(true)
    end
  end

  describe "HasPhoneNumber" do
    shared_examples "HasPhoneNumber" do
      describe "validation hooks" do
        it "is invalid when number is wrong" do
          object = build(factory, phone_number: "invalid value")
          object.validate

          expect(object.errors).to include(:phone_number)
        end

        it "is valid when number is good" do
          element = build(factory, phone_number: "0123456789")
          element.validate

          expect(element.errors).not_to include(:phone_number)
        end
      end

      describe "formatting hooks" do
        context "on create" do
          it "return nil with blank phone number" do
            expect(create(factory, phone_number: nil).phone_number_formatted).to be_nil
            expect(create(factory, phone_number: "").phone_number_formatted).to be_nil
          end

          it "return valid +33 given phone number" do
            expect(create(factory, phone_number: "01 30 30 40 40").phone_number_formatted).to eq("+33130304040")
          end
        end

        context "on update" do
          it "updates it" do
            object = create(factory, phone_number: "01 30 30 40 40")
            expect(object.phone_number_formatted).to eq("+33130304040")
            object.update!(phone_number: "04 300 32020")
            expect(object.phone_number_formatted).to eq("+33430032020")
            object.update!(phone_number: "")
            expect(object.phone_number_formatted).to be_nil
          end
        end
      end
    end

    [User, Territory, Lieu].each do |klass|
      describe(klass) do
        let(:factory) { described_class.name.underscore }

        include_examples "HasPhoneNumber"
      end
    end
  end
end
