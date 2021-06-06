# frozen_string_literal: true

describe HasPhoneNumberConcern do
  shared_examples "has phone number concern" do |element|
    describe "phone number validation" do
      def errors_with_phone(phone_number)
        user = build(:user, phone_number: phone_number)
        user.validate
        user.errors.details[:phone_number]
      end

      it "prevents malformed numbers" do
        expect(errors_with_phone("wrong value")).not_to be_empty
        expect(errors_with_phone("06 12 34 56 7")).not_to be_empty
        expect(errors_with_phone(" +33 6 10 00 00 00 1")).not_to be_empty
      end

      it "allows ten-digit DROM numbers" do
        expect(errors_with_phone("    06 10 00 00 00")).to be_empty
        expect(errors_with_phone(" +33 6 10 00 00 00")).to be_empty
        expect(errors_with_phone("    06 90 00 00 00")).to be_empty
        expect(errors_with_phone("+590 6 90 00 00 00")).to be_empty
        expect(errors_with_phone(" +33 6 90 00 00 00")).not_to be_empty
        expect(errors_with_phone("    06 93 00 00 00")).to be_empty
        expect(errors_with_phone("+262 6 93 00 00 00")).to be_empty
        expect(errors_with_phone(" +33 6 93 00 00 00")).not_to be_empty
        expect(errors_with_phone("    06 94 00 00 00")).to be_empty
        expect(errors_with_phone("+594 6 94 00 00 00")).to be_empty
        expect(errors_with_phone(" +33 6 94 00 00 00")).not_to be_empty
        expect(errors_with_phone("    06 96 00 00 00")).to be_empty
        expect(errors_with_phone("+596 6 96 00 00 00")).to be_empty
        expect(errors_with_phone(" +33 6 96 00 00 00")).not_to be_empty
      end

      it "allows international numbers" do
        expect(errors_with_phone("+1 2014000000")).to be_empty   # USA
        expect(errors_with_phone("+212 5222-54321")).to be_empty # Maroc
      end
    end

    describe "phone_number formatted normalization" do
      context "on create" do
        it "return nil with nil phone number" do
          expect(create(element, phone_number: nil).phone_number_formatted).to eq(nil)
        end

        it "return nil with a blank phone number" do
          expect(create(element, phone_number: "").phone_number_formatted).to eq(nil)
        end

        it "return valid +33 given phone number" do
          expect(create(element, phone_number: "01 30 30 40 40").phone_number_formatted).to eq("+33130304040")
        end

        it "not save with an invalid phone number" do
          expect(build(element, phone_number: "01 30 20").save).to be false
        end
      end

      context "on update" do
        context "previous phone number" do
          it "updates it" do
            created_element = create(element, phone_number: "01 30 30 40 40")
            expect(created_element.phone_number_formatted).to eq("+33130304040")
            created_element.update!(phone_number: "04 300 32020")
            expect(created_element.phone_number_formatted).to eq("+33430032020")
            created_element.update!(phone_number: "")
            expect(created_element.phone_number_formatted).to eq(nil)
          end
        end
      end
    end
  end

  it_behaves_like "has phone number concern", :user, :rdv
end
