#!/usr/bin/env ruby
# frozen_string_literal: true

# encoding=utf-8
require 'digest'

$pd = false

class Hash
  # text from code
  # orig fcb has dname, oname, title
  def fenced_name
    fetch(:oname, nil).tap { |ret| pp [__LINE__, 'Hash.fenced_name() ->', ret] }
  end

  # block name in commands and documents
  def pub_name(**kwargs)
    full = fetch(:nickname, nil) || fetch(:oname, nil)
    full&.to_s&.pub_name(**kwargs).tap { |ret| pp [__LINE__, 'Hash.pub_name() ->', ret] if $pd }
  end
end

class String
  FN_ID_LEN = 4
  FN_MAX_LEN = 64
  FN_PATTERN = %r{[^!#%\+\-0-9=@A-Z_a-z()\[\]{}]}.freeze # characters than can be used in a file name without quotes or escaping
  # except '.', ',', '~' reserved for tokenization
  # / !"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~
  FN_REPLACEMENT = '_'

  # block name in commands and documents
  def pub_name(
    id_len: FN_ID_LEN, max_len: FN_MAX_LEN,
    pattern: FN_PATTERN, replacement: FN_REPLACEMENT
  )
    trimmed = if self[max_len]
                rand(((10**(id_len - 1)) + 1)..(10**id_len)).to_s
                dig = Digest::MD5.hexdigest(self)[0, id_len]
                self[0..max_len - id_len] + dig
              else
                self
              end

    trimmed.gsub(pattern, replacement).tap { |ret| pp [__LINE__, 'String.pub_name() ->', ret] if $pd }
  end
end

