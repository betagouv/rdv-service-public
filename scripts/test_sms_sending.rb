# frozen_string_literal: true

# DebugLogger:
#
# TEST_PHONE_NUMBER=<0639981234> rails runner scripts/test_sms_sending.rb

# NetSize:
#
# DEFAULT_SMS_PROVIDER=netsize DEFAULT_SMS_PROVIDER_KEY=<user:password> TEST_PHONE_NUMBER=<0639981234> rails runner scripts/test_sms_sending.rb

# SendInBlue
#
# DEFAULT_SMS_PROVIDER=send_in_blue DEFAULT_SMS_PROVIDER_KEY=<api_key> TEST_PHONE_NUMBER=<0639981234> rails runner scripts/test_sms_sending.rb

SendTransactionalSmsService.perform_with(ENV["TEST_PHONE_NUMBER"], "this is test " * 3, ["test"])
