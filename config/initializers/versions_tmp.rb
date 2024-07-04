class PaperTrail::Version < ::ActiveRecord::Base
  self.ignored_columns = %i[old_object old_object_changes]
end
