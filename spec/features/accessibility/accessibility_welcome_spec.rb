# frozen_string_literal: true

require "spec_helper"

describe "welcome", js: true do
  it "index is accessible" do
    visit root_path
    expect(page).to be_axe_clean
  end
end
