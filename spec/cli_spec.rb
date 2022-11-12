# frozen_string_literal: true

require 'rspec'
require_relative '../lib/cli'

puts "SPEC:#{__FILE__}" if ENV.fetch('SPEC_DEBUG', nil).tap { |val| val.nil? ? false : !(val.empty? || val == '0') }

include CLI

RSpec.describe 'CLI' do
  it { expect(value_for_cli(false)).to eq '0' }
  it { expect(value_for_cli(true)).to eq '1' }
  it { expect(value_for_cli(2)).to eq '2' }
  it { expect(value_for_cli('a')).to eq 'a' }
  it { expect(value_for_cli('a b')).to eq 'a\ b' }
end
