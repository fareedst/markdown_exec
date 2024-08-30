# frozen_string_literal: true

require 'rspec'
require_relative '../lib/cli'
require_relative '../lib/rspec_helpers'
spec_source __FILE__

include CLI

RSpec.describe 'CLI' do
  it { expect(value_for_cli(false)).to eq 'f' }
  it { expect(value_for_cli(true)).to eq 't' }
  it { expect(value_for_cli(2)).to eq '2' }
  it { expect(value_for_cli('a')).to eq 'a' }
  it { expect(value_for_cli('a b')).to eq 'a\ b' }
end
