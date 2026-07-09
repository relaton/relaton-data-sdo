# frozen_string_literal: true

require "yaml"

# Repo root (spec/ lives directly under it).
ROOT = File.expand_path("..", __dir__)

require File.join(ROOT, "build_index")

RSpec.configure do |config|
  config.expect_with(:rspec) { |c| c.syntax = :expect }
  config.disable_monkey_patching!
  config.order = :random
end

# Every org source directory under orgs/.
def org_dirs
  Dir[File.join(ROOT, "orgs", "*")].select { |d| File.directory?(d) }.sort
end
