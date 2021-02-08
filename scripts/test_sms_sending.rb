SendTransactionalSmsService.new(
  OpenStruct.new(
    phone_number_formatted: "33699999999",
    content: "this is test" * 40,
    tags: ["test"]
  )
).perform

# FORCE_SMS_PROVIDER=netsize rails runner scripts/test_sms_sending.rb
