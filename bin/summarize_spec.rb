require_relative 'summarize_beacon'
require 'rspec'

describe 'Summarize beacon' do

  before(:example) do
    @summarize_beacon = SummarizeBeacon.new
  end

  describe 'Connection' do

    it 'should return two values for 2 minutes' do
      expect(@summarize_beacon.get_values(from:1435772877, to:1435772937).length).to be_eql(2)
    end

    it 'should return single value if \'to\' not defined' do
      expect(@summarize_beacon.get_values(from:1435772877).length).to be_eql(1)
    end

    it 'should return single value if nothing not defined' do
      expect(@summarize_beacon.get_values({}).length).to be_eql(1)
    end

    it 'should raise exception when \'from\' attribute higher than \'to\'' do
      expect { @summarize_beacon.get_values(to:1435772877, from:1435772937)}.to raise_error()
    end

    it 'should raise exception if host not found' do
      stub_const("SummarizeBeacon::RECORD_LAST_URL", 'https://beac111on.nist.gov/rest')
      expect { @summarize_beacon.get_values({})}.to raise_error()
    end

  end

  describe 'Arguments parsing' do

  end

end

RSpec::Expectations.configuration.warn_about_potential_false_positives = false