# frozen_string_literal: true

describe UserNotificationsHelper do
  describe "#user_notifiable_by_sms_text" do
    it "allow SMS notifications" do
      user = build(:user, phone_number: "06 65 87 89 53")
      expected = "<b>06 65 87 89 53</b> <span>(notifications par SMS activées)</span>"
      expect(user_notifiable_by_sms_text(user)).to eq(expected)
    end

    it "disallow SMS notifications" do
      user = build(:user, notify_by_sms: false, phone_number: "06 65 87 89 53")
      expected = "<b>06 65 87 89 53</b> <span>(notifications par SMS désactivées)</span>"
      expect(user_notifiable_by_sms_text(user)).to eq(expected)
    end

    it "not a phone number" do
      user = build(:user, notify_by_sms: true, phone_number: "01 65 87 89 53")
      expected = "<b>01 65 87 89 53</b> <span>(notifications par SMS impossibles car le numéro n&#39;est pas mobile)</span>"
      expect(user_notifiable_by_sms_text(user)).to eq(expected)
    end

    it "no phone number" do
      user = build(:user, notify_by_sms: true, phone_number: nil)
      expected = "<b>Non renseigné</b> "
      expect(user_notifiable_by_sms_text(user)).to eq(expected)
    end
  end
end
