#!/usr/bin/env ruby
# frozen_string_literal: true

# encoding=utf-8

class Array
  def pluck(key)
    map { |hash| hash[key] if hash.is_a?(Hash) }.compact
  end

  # Processes each element of the array, yielding the previous, current, and next elements to the given block.
  # Deletes the current element if the block returns true.
  # @return [Array] The modified array after conditional deletions.
  def process_and_conditionally_delete!
    i = 0
    while i < length
      prev_item = self[i - 1] unless i.zero?
      current_item = self[i]
      next_item = self[i + 1]

      should_delete = yield prev_item, current_item, next_item
      if should_delete
        delete_at(i)
      else
        i += 1
      end
    end

    self
  end
end
