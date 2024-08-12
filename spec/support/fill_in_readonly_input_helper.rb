module FillInReadOnlyInputHelper
  def fill_in_readonly_input(selector, value)
    # cf https://github.com/teamcapybara/capybara/issues/1178
    # this should work both with js: true and without
    find(selector).native["value"] = value
  end
end
