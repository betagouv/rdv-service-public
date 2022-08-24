# frozen_string_literal: true

# DebugLogger:
#
# TEST_PHONE_NUMBER=<0639981234> rails runner scripts/sms_sender_test.rb

# NetSize:
#
# DEFAULT_SMS_PROVIDER=netsize DEFAULT_SMS_PROVIDER_KEY=<user:password> TEST_PHONE_NUMBER=<0639981234> rails runner scripts/sms_sender_test.rb

# SendInBlue
#
# DEFAULT_SMS_PROVIDER=send_in_blue DEFAULT_SMS_PROVIDER_KEY=<api_key> TEST_PHONE_NUMBER=<0639981234> rails runner scripts/sms_sender_test.rb

# Contact Experience
#
# DEFAULT_SMS_PROVIDER=contact_experience DEFAULT_SMS_PROVIDER_KEY=<dev_code> TEST_PHONE_NUMBER=<0639981234> rails runner scripts/sms_sender_test.rb

SmsSender.perform_with("RdvSoli", ENV["TEST_PHONE_NUMBER"], "this is a test " * 20, ["test"], nil, nil, {})
