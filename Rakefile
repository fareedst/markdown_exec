# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rake/testtask'

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/**/*_test.rb']
end

require 'rubocop/rake_task'

RuboCop::RakeTask.new

require_relative 'lib/markdown_exec/version'

task default: %i[test rubocop]

# task :default => :build

task :build do
  system "gem build #{MarkdownExec::GEM_NAME}.gemspec"
end

task install: :build do
  system "gem install #{MarkdownExec::GEM_NAME}-#{MarkdownExec::VERSION}.gem"
end

task publish: :build do
  system "gem push #{MarkdownExec::GEM_NAME}-#{MarkdownExec::VERSION}.gem"
end

task uninstall: :build do
  system "gem uninstall #{MarkdownExec::GEM_NAME}"
end

task :clean do
  system 'rm *.gem'
end
