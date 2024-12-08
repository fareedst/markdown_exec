# frozen_string_literal: true

require_relative 'lib/markdown_exec/version'

Gem::Specification.new do |spec|
  spec.name = MarkdownExec::GEM_NAME
  spec.version = MarkdownExec::VERSION
  spec.authors = ['Fareed Stevenson']
  spec.email = ['fareed@phomento.com']

  spec.summary =
    'Interactively select and execute fenced code blocks in markdown files.'
  spec.description =
    'Interactively select and execute fenced code blocks in markdown files.' \
    ' Build complex scripts by naming and requiring blocks.' \
    ' Log resulting scripts and output.' \
    ' Re-run scripts.'
  spec.homepage = 'https://rubygems.org/gems/markdown_exec'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 2.6.0'
  spec.post_install_message = '
To install tab completion:
- Append a command to load the completion script to your shell configuration file.
- This gem must be installed and executable for the command to be composed correctly.

echo "source $(mde --pwd)/bin/tab_completion.sh" >> ~/.bash_profile

'

  # spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata['changelog_uri'] = 'https://github.com/fareedst/markdown_exec/blob/main/CHANGELOG.md'
  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['rubygems_mfa_required'] = 'true'
  spec.metadata['source_code_uri'] = 'https://github.com/fareedst/markdown_exec'

  # include unchecked files from lib folder
  #
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      # rubocop:disable Layout/LineLength
      (f == __FILE__) ||
        f.match(%r{\A(?:(?:test|spec|features|fixtures)/|\.(?:git|travis|circleci)|appveyor)})
      # rubocop:enable Layout/LineLength
    end
  end + Dir['lib/*'] - ['lib/rb.rb']

  spec.bindir = 'bin'
  spec.executables = %w[mde tab_completion.sh]
  spec.require_paths = ['lib']

  spec.add_dependency 'clipboard', '~> 1.3.6'
  spec.add_dependency 'open3', '~> 0.1.1'
  spec.add_dependency 'optparse', '~> 0.1.1'
  spec.add_dependency 'tty-prompt', '~> 0.23.1'
  spec.add_dependency 'yaml', '~> 0.2'
end
