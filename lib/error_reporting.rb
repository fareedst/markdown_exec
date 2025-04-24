# frozen_string_literal: true

# encoding=utf-8

##
# Module providing standardized error‐reporting:
# logs either an Exception’s details or a simple
# string message—optionally with context—and then
# re‐raises either the original Exception or a new
# RuntimeError for string messages.
#
# Including this module gives you:
#  • instance method  → report_and_reraise(...)
#  • class method     → report_and_reraise(...)
module ErrorReporting
  def self.included(base)
    base.extend(self)
  end

  def report_and_reraise(error_or_message, context: nil)
    if error_or_message.is_a?(Exception)
      header = +"#{error_or_message.class}: #{error_or_message.message}"
      header << " (#{context})" if context

      ww header
      ww error_or_message.backtrace.join("\n") if error_or_message.backtrace

      raise error_or_message
    else
      header = +error_or_message.to_s
      header << " (#{context})" if context

      ww header

      raise error_or_message.to_s
    end
  end
end
