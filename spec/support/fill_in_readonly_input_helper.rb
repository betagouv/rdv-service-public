module FillInReadOnlyInputHelper
  def fill_in_readonly_input(selector, value)
    if RSpec.current_example.metadata[:js]
      find(selector) # so that it waits for the page to load
      page.execute_script("document.querySelector('#{selector}').value = '#{value}'")
    else
      # cf https://github.com/teamcapybara/capybara/issues/1178
      find(selector).native["value"] = value
    end
  end
end
