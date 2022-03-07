# frozen_string_literal: true

require_relative 'markdown_exec/version'

module MarkdownExec
  class Error < StandardError; end

  # Markdown Exec
  class MDExec
    def self.echo(str = '')
      "#{str}#{str}"
    end
  end
end
