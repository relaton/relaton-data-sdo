# frozen_string_literal: true

require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

desc "Build the merged index.yaml from orgs/*"
task :build do
  ruby "build_index.rb"
end

task default: :spec
