# frozen_string_literal: true

require_relative 'lib/markdown_exec/version'

Gem::Specification.new do |spec|
  spec.name = MarkdownExec::GEM_NAME
  spec.version = MarkdownExec::VERSION
  spec.authors = ['Fareed Stevenson']
  spec.email = ['fareed@phomento.com']

  spec.summary = 'Execute shell blocks in markdown files.'
  spec.description = 'Interactively select and execute shell blocks in markdown files.' \
                     ' Build complex scripts by naming blocks and requiring named blocks.'
  spec.homepage = 'https://rubygems.org/gems/markdown_exec'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 2.6.0'

  # spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/fareedst/markdown_exec'
  spec.metadata['changelog_uri'] = 'https://github.com/fareedst/markdown_exec/blob/main/CHANGELOG.md'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.executables = ['mde']
  spec.require_paths = ['lib']

  spec.add_dependency 'open3', '~> 0.1.1'
  spec.add_dependency 'optparse', '~> 0.1.1'
  spec.add_dependency 'tty-prompt', '~> 0.23.1'
  spec.add_dependency 'yaml', '~> 0.2.0'
end
