require_relative 'summarize_beacon'
require 'rspec'
require 'rspec/mocks'

RSpec.configure do |config|
  config.mock_with :mocha
  $stderr = $stdout = StringIO.new
end

describe 'Summarize beacon' do

  before(:example) do
    @summarize_beacon = SummarizeBeacon.new
    @time_now = Time.parse("02/02/2002 10:10:10")
    Time.stubs(:now).returns(@time_now)
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
      SummarizeBeacon.const_set(:RECORD_LAST_URL, 'https://beac111on.nist.gov/rest')
      expect { @summarize_beacon.get_values({})}.to raise_error()
    end

  end

  describe 'Arguments parsing' do
    it 'should raise exception if attribute \'from\' contains incorrect value' do
      expect { @summarize_beacon.parse_arguments(['--from "aaa"'])}.to raise_error()
    end

    it 'should raise exception if attribute \'to\' contains incorrect value' do
      expect { @summarize_beacon.parse_arguments(['--from "" --to "aaa"'])}.to raise_error()
    end

    it 'should return current time' do
      expect( @summarize_beacon.parse_arguments(['--from', '0 minutes ago', '--to', '0 minutes ago'])).to have_key(:from)
      expect( @summarize_beacon.parse_arguments(['--from', '0 minutes ago', '--to', '0 minutes ago'])).to have_key(:to)
      expect( @summarize_beacon.parse_arguments(['--from', '0 minutes ago', '--to', '0 minutes ago'])[:from]).to eql(@time_now.utc.to_i)
      expect( @summarize_beacon.parse_arguments(['--from', '0 minutes ago', '--to', '0 minutes ago'])[:to]).to eql(@time_now.utc.to_i)
    end

    it 'should calculate date correctly' do
      expected_time = Time.parse("01/01/2002 09:09:10").to_i
      expect( @summarize_beacon.parse_arguments(['--from', '1 month 1 day 1 hour 1 minutes ago'])[:from]).to eql(expected_time)
    end
  end

  describe 'Summarizer' do
    it 'should count values successfully' do
      expect( @summarize_beacon.summarize(['0123456789ABCDEF'])).to eql({'0'=>1, '1'=>1, '2'=>1, '3'=>1, '4'=>1, '5'=>1, '6'=>1, '7'=>1, '8'=>1, '9'=>1, 'A'=>1, 'B'=>1, 'C'=>1, 'D'=>1, 'E'=>1, 'F'=>1})
      expect( @summarize_beacon.summarize(['0123CDEF'])).to eql({'0'=>1, '1'=>1, '2'=>1, '3'=>1, 'C'=>1, 'D'=>1, 'E'=>1, 'F'=>1})
    end

    it 'should sum values successfully' do
      expect( @summarize_beacon.summarize(['0123456789ABCDEF','0123456789ABCDEF'])).to eql({'0'=>2, '1'=>2, '2'=>2, '3'=>2, '4'=>2, '5'=>2, '6'=>2, '7'=>2, '8'=>2, '9'=>2, 'A'=>2, 'B'=>2, 'C'=>2, 'D'=>2, 'E'=>2, 'F'=>2})
      expect( @summarize_beacon.summarize(['0123CDEF','0123456789ABCDEF'])).to eql({'0'=>2, '1'=>2, '2'=>2, '3'=>2, '4'=>1, '5'=>1, '6'=>1, '7'=>1, '8'=>1, '9'=>1, 'A'=>1, 'B'=>1, 'C'=>2, 'D'=>2, 'E'=>2, 'F'=>2})
    end
  end

end

RSpec::Expectations.configuration.warn_about_potential_false_positives = false
