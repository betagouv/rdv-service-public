# frozen_string_literal: true

describe HasPhoneNumberConcern do
  shared_examples "has phone number concern" do |element|
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
