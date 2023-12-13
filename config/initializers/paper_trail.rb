# See https://github.com/paper-trail-gem/paper_trail/blob/master/doc/pt_13_yaml_safe_load.md#to-continue-using-the-yaml-serializer

::ActiveRecord.use_yaml_unsafe_load = false
::ActiveRecord.yaml_column_permitted_classes = [
  ::ActiveRecord::Type::Time::Value,
  ::ActiveSupport::TimeWithZone,
  ::ActiveSupport::TimeZone,
  ::BigDecimal,
  ::Date,
  ::Symbol,
  ::Time,
]
