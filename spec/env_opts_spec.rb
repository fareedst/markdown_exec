# frozen_string_literal: true

require 'rspec'
require_relative '../lib/env_opts'

include Tap #; tap_config
require_relative '../lib/rspec_helpers'
spec_source __FILE__

RSpec.describe 'EnvOpts' do
  describe 'initialize' do
    subject(:envopts) { EnvOpts.new(opts, nil) }

    describe 'method_missing' do
      let(:opts) { { value: { default: '_option', cast: :to_s } } }

      it 'accesses option value' do
        expect(envopts.value).to eq '_option'
      end
    end

    describe 'adds option' do
      let(:double) { instance_double(EnvOpts) }
      let(:opts) { { value: { default: '_option' } } }

      it 'sets default value' do
        allow(EnvOpts).to receive(:new).and_return(double)
        allow(double).to receive(:set_key_value_raw).with('value', '_option')
        expect(double).not_to be_nil
      end
    end

    context 'when default value in :default' do
      let(:opts) { { version: { default: '_option' } } }

      it 'returns default' do
        expect(envopts.version).to be '_option'
      end
    end

    context 'when default value in :d' do
      let(:opts) { { version: { d: '_option' } } }

      it 'returns default' do
        expect(envopts.version).to be '_option'
      end
    end
  end

  describe 'parse command' do
    subject(:envopts) { EnvOpts.new(opts, nil).parse(command) }

    let(:command) { [] }

    context 'when option sets fixed value' do
      let(:opts) { { version: { default: false, fixed: true } } }
      let(:command) { %w[--version] }

      it 'returns default' do
        expect(envopts.version).to be true
      end
    end

    describe 'init options' do
      let(:opts) { { value: { default: '_option' } } }

      it 'sets default value' do
        expect(envopts.values['value']).to eq '_option'
      end

      it 'sets option' do
        expect(envopts.opts['value'][:default]).to eq '_option'
      end
    end

    describe 'parse yields' do
      let(:opts) { { value: { default: '_option' } } }
      let(:command2) { %w[ping] }

      it 'yields unprocessed options' do
        envopts.parse(command2) do |type, data|
          expect(type).to eq 'NAO'
          expect(data).to eq ['ping']
        end
      end
    end
  end

  describe 'parse command with cast types' do
    subject(:envopts) { EnvOpts.new(opts, nil).parse(command) }

    let(:command) { %w[--value 2] }
    let(:opts) { { value: { default: '_option', cast: type } } }

    context 'when type is float' do
      let(:type) { :to_f }

      it 'sets as float' do
        expect(envopts.values['value']).to eq 2.0
      end
    end

    context 'when type is integer' do
      let(:type) { :to_i }

      it 'sets as integer' do
        expect(envopts.values['value']).to eq 2
      end
    end

    context 'when type is string' do
      let(:type) { :to_s }

      it 'sets as string' do
        expect(envopts.values['value']).to eq '2'
      end
    end

    context 'when cast is unspecified' do
      let(:opts) { { value: { default: '_option' } } }

      it 'sets as string' do
        expect(envopts.values['value']).to eq '2'
      end
    end
  end

  describe '' do
    subject(:envopts) { EnvOpts.new(opts, nil).parse(command) }

    let(:command) { [] }
    let(:envvar) { 'DEFAULT' }
    let(:opts) { { varname => { default: '_option', env: envvar, cast: :to_s } } }
    let(:varname) { 'value' }

    it 'displays help' do
      expect(envopts.help).to eq '--value  DEFAULT  _option  :to_s'
    end
  end

  # value priority: default < configuration < arguments
  #
  describe 'settings priority' do
    subject(:envopts) { EnvOpts.new(opts, nil).parse(command) }

    let(:envvar) { 'DEFAULT' }
    let(:opts) { [[varname, { default: '_option', env: envvar, cast: :to_s }]].to_h }
    let(:varname) { 'value' }

    before do
      ENV[envvar] = '_environment'
    end

    context 'without arguments' do
      let(:command) { [] }

      it 'sets options default' do
        expect(envopts.opts[varname][:default]).to eq '_option'
      end

      it 'sets value after environment' do
        expect(envopts.values[varname]).to eq '_environment'
      end
    end

    context 'with arguments' do
      let(:command) { ["--#{varname}", '_argument'] }

      it 'sets value after arguments' do
        expect(envopts.values[varname]).to eq '_argument'
      end
    end
  end

  describe 'converts names' do
    it 'symbol_name_to_option_name' do
      expect(EnvOpts.symbol_name_to_option_name(:_a_b_)).to eq '-a-b-'
    end
  end
end
