# frozen_string_literal: true

describe HasPhoneNumberConcern do
  describe "phone_number formatted normalization" do
    context "on create" do
      it "return nil with nil phone number" do
        expect(create(:user, phone_number: nil).phone_number_formatted).to eq(nil)
      end

      it "return nil with a blank phone number" do
        expect(create(:user, phone_number: "").phone_number_formatted).to eq(nil)
      end

      it "return valid +33 given phone number" do
        expect(create(:user, phone_number: "01 30 30 40 40").phone_number_formatted).to eq("+33130304040")
      end

      it "not save with an invalid phone number" do
        expect(build(:user, phone_number: "01 30 20").save).to be false
      end
    end

    context "on update" do
      context "previous phone number" do
        it "updates it" do
          user = create(:user, phone_number: "01 30 30 40 40")
          expect(user.phone_number_formatted).to eq("+33130304040")
          user.update!(phone_number: "04 300 32020")
          expect(user.phone_number_formatted).to eq("+33430032020")
          user.update!(phone_number: "")
          expect(user.phone_number_formatted).to eq(nil)
        end
      end
    end
  end
end
