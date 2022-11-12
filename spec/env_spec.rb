# frozen_string_literal: true

require 'rspec'
require_relative '../lib/env'

puts "SPEC:#{__FILE__}" if ENV.fetch('SPEC_DEBUG', nil).tap { |val| val.nil? ? false : !(val.empty? || val == '0') }

include Env

RSpec.describe 'Env' do
  let(:default_int) { 2 }
  let(:default_str) { 'a' }

  describe 'env_bool' do
    it 'returns default false when environment variable is missing' do
      expect(env_bool(nil, default: false)).to be false
    end

    it 'returns default true when environment variable is missing' do
      expect(env_bool(nil, default: true)).to be true
    end

    it 'returns default false for empty string in environment' do
      ENV['X'] = ''
      expect(env_bool('X')).to be false
    end

    it 'returns false for 0 in environment' do
      ENV['X0'] = '0'
      expect(env_bool('X0')).to be false
    end

    it 'returns true for 1 in environment' do
      ENV['X1'] = '1'
      expect(env_bool('X1')).to be true
    end
  end

  describe 'env_bool_false' do
    it 'returns default when environment variable is missing' do
      expect(env_bool_false(nil)).to be false
    end

    it 'returns default for empty string in environment' do
      ENV['X'] = ''
      expect(env_bool_false('X')).to be false
    end

    it 'returns false for 0 in environment' do
      ENV['X0'] = '0'
      expect(env_bool_false('X0')).to be false
    end

    it 'returns true for 1 in environment' do
      ENV['X1'] = '1'
      expect(env_bool_false('X1')).to be true
    end
  end

  describe 'env_int' do
    it 'returns default when environment variable is missing' do
      expect(env_int(nil, default: default_int)).to be default_int
    end

    it 'returns default for empty string in environment' do
      ENV['X'] = ''
      expect(env_int('X', default: default_int)).to be default_int
    end

    it 'returns integer from environment' do
      ENV['X1'] = '1'
      expect(env_int('X1', default: default_int)).to be 1
    end
  end

  describe 'env_str' do
    it 'returns default when environment variable is missing' do
      expect(env_str(nil, default: default_str)).to be default_str
    end

    it 'returns empty string from environment' do
      ENV['X'] = ''
      expect(env_str('X', default: default_str)).to eq ''
    end

    it 'returns non-empty string from environment' do
      ENV['X1'] = '1'
      expect(env_str('X1', default: default_str)).to eq '1'
    end
  end
end
