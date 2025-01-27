Rails.application.config.after_initialize do
  LetterOpenerWeb::Letter.class_eval do
    alias_method :original_adjust_link_targets, :adjust_link_targets
    def adjust_link_targets(contents)
      original_adjust_link_targets(contents).gsub(".localhost/", ".localhost:3000/")
    end
  end
end
