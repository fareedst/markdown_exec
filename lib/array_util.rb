#!/usr/bin/env ruby
# frozen_string_literal: true

# encoding=utf-8

module ArrayUtil
  def self.partition_by_predicate(arr)
    true_list = []
    false_list = []

    arr.each do |element|
      if yield(element)
        true_list << element
      else
        false_list << element
      end
    end

    [true_list, false_list]
  end
end
