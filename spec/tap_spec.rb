# frozen_string_literal: true

require 'rspec'
require_relative '../lib/tap'

include Tap
require_relative '../lib/rspec_helpers'
spec_source __FILE__

# :reek:UtilityFunction
def hide_stdout
  $stdout = StringIO.new # do not display stdout
end

RSpec.describe 'Tap' do
  before do |_variable|
    tap_config enable: true, value: ALL2
  end

  let(:name) { 'name1' }
  let(:source) { 'source1' }
  let(:val) { 246 }

  describe 'tap_inspect' do
    it 'must be enabled' do
      tap_config enable: false
      expect { val.tap_inspect }.to output('').to_stdout
    end

    it 'returns self' do
      hide_stdout
      expect(val.tap_inspect).to eq val
    end

    it 'outputs value' do
      expect { val.tap_inspect name: '' }.to output("#{val.inspect}\n").to_stdout
    end

    it 'selects output with mask' do
      expect do
        val.tap_inspect mask: T1, name: ''
      end.to output("#{val.inspect}\n").to_stdout
    end

    it 'filters output with mask' do
      expect { val.tap_inspect mask: T4, name: '' }.to output('').to_stdout
    end

    it 'includes caller in output' do
      expect do
        val.tap_inspect name: '',
                        caller_first: caller[0]
      end.to output("capture() #{val.inspect}\n").to_stdout
    end

    it 'includes source in output' do
      expect do
        val.tap_inspect name: '',
                        source: source
      end.to output("#{source} #{val.inspect}\n").to_stdout
    end

    it 'prefixes output with name from named variable' do
      expect do
        val.tap_inspect name: name
      end.to output("#{name}: #{val.inspect}\n").to_stdout
    end

    it 'prefixes output with name from position variable' do
      expect { val.tap_inspect name }.to output("#{name}: #{val.inspect}\n").to_stdout
    end

    it 'applies type JSON' do
      expect do
        val.tap_inspect name: '', type: :json
      end.to output("#{val.to_json}\n").to_stdout
    end

    it 'applies type STRING' do
      expect { val.tap_inspect name: '', type: :to_s }.to output("#{val}\n").to_stdout
    end

    it 'applies type YAML' do
      expect { val.tap_inspect name: '', type: :yaml }.to output(val.to_yaml).to_stdout
    end
  end

  # def tap_print(mask: TDD)

  describe 'tap_print' do
    it 'must be enabled' do
      tap_config enable: false
      expect { val.tap_print }.to output('').to_stdout
    end

    it 'returns self' do
      hide_stdout
      expect(val.tap_print).to eq val
    end

    it 'outputs value' do
      expect { val.tap_print }.to output(val.to_s).to_stdout
      # expect($stdout).to receive(:print).with(val)
      # val.tap_print
    end

    it 'selects output with mask' do
      expect { val.tap_print mask: T1 }.to output(val.to_s).to_stdout
    end

    it 'filters output with mask' do
      expect { val.tap_print mask: T4 }.to output('').to_stdout
    end
  end

  # def tap_puts(name_ = nil, mask: TDD, name: nil)

  describe 'tap_puts' do
    it 'must be enabled' do
      tap_config enable: false
      expect { val.tap_puts }.to output('').to_stdout
    end

    it 'returns self' do
      hide_stdout
      expect(val.tap_puts).to eq val
    end

    it 'outputs value' do
      expect { val.tap_puts }.to output("#{val}\n").to_stdout
    end

    it 'selects output with mask' do
      expect { val.tap_puts mask: T1 }.to output("#{val}\n").to_stdout
    end

    it 'filters output with mask' do
      expect { val.tap_puts mask: T4 }.to output('').to_stdout
    end

    it 'prefixes output with name from named variable' do
      expect { val.tap_puts name: name }.to output("#{name}: #{val}\n").to_stdout
    end

    it 'prefixes output with name from position variable' do
      expect { val.tap_puts name }.to output("#{name}: #{val}\n").to_stdout
    end
  end

  # def tap_yaml(name_ = nil, caller_first: nil, mask: TDD, name: DN, source: nil)

  describe 'tap_yaml' do
    it 'must be enabled' do
      tap_config enable: false
      expect { val.tap_yaml }.to output('').to_stdout
    end

    it 'returns self' do
      expect(val.tap_yaml).to eq val
    end

    it 'outputs value' do
      expect { val.tap_yaml name: '' }.to output(val.to_yaml).to_stdout
      # expect($stdout).to receive(:puts).with(val.to_yaml)
      # val.tap_yaml name: ''
    end

    it 'selects output with mask' do
      expect { val.tap_yaml mask: T1, name: '' }.to output(val.to_yaml).to_stdout
    end

    it 'filters output with mask' do
      expect { val.tap_yaml mask: T4, name: '' }.to output('').to_stdout
    end

    it 'includes caller in output' do
      expect do
        val.tap_yaml name: '',
                     caller_first: caller[0]
      end.to output("capture() #{val.to_yaml}").to_stdout
    end

    it 'includes source in output' do
      expect do
        val.tap_yaml name: '', source: source
      end.to output("#{source} #{val.to_yaml}").to_stdout
    end

    it 'prefixes output with name from named variable' do
      expect { val.tap_yaml name: name }.to output("#{name}: #{val.to_yaml}").to_stdout
    end

    it 'prefixes output with name from position variable' do
      expect { val.tap_yaml name }.to output("#{name}: #{val.to_yaml}").to_stdout
    end
  end
end
