#!/usr/bin/env ruby

# inspired by https://shime.sh/til/running-parallel-rails-tests-on-github-actions

require "date"

# Add some randomization. Different test order for every run.
tests = Dir["spec/**/*_spec.rb"]
  .shuffle(random: Random.new(ENV["GITHUB_RUN_ID"].to_i))
  .select
  .with_index do |_el, i|
    i % ENV["NUMBER_OF_NODES"].to_i == ENV["CI_NODE_INDEX"].to_i
  end

exec "bundle exec rspec #{tests.join(' ')}"
