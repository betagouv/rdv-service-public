def check_or_click_submit(text)
  if Capybara.current_driver == Capybara.javascript_driver
    check(text, allow_label_click: true)
  else
    click_button(text)
  end
end
