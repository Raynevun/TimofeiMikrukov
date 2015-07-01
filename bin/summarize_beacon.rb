require 'rest-client'
require 'rexml/document'
require 'active_support/all'
require 'optparse'

class SummarizeBeacon

  URL = 'https://beacon.nist.gov/rest'
  RECORD_URL = "#{URL}/record"
  RECORD_LAST_URL = "#{URL}/record/last"
  NEXT_URL = "#{URL}/record/next"
  DATE_KEYWORDS = ['months', 'days', 'hours', 'minutes']

  #Method returns list of all beacons. Can be used with timestamp parameters :from and :to
  def get_values(args)
    output_value = []

    if !args.has_key?(:from) #Get last value if we don't have 'from' parameter defined
      result_xml = RestClient.get("#{RECORD_LAST_URL}/#{args[:from]}")
      output_value << REXML::Document.new(result_xml).get_text('/record/outputValue').value
    elsif !args.has_key?(:to) #if defined only from parameter
      result_xml = RestClient.get("#{RECORD_URL}/#{args[:from]}")
      output_value << REXML::Document.new(result_xml).get_text('/record/outputValue').value
    else #both parameters defined
      raise('Parameter \'from\' cannot be higher that parameter \'to\'') if args[:from]>args[:to]

      parsed_xml = REXML::Document.new(RestClient.get("#{RECORD_URL}/#{args[:from]}"))
      output_value << parsed_xml.get_text('/record/outputValue').value
      #collecting all values. should be done in multithreading
      while ((timestamp = parsed_xml.get_text('/record/timeStamp')) < args[:to])
        parsed_xml = REXML::Document.new(RestClient.get("#{NEXT_URL}/#{timestamp}"))
        output_value << parsed_xml.get_text('/record/outputValue').value
      end
    end

    return output_value
  end

  #Counting all beacons characters and return hash with character as key and amount of appearance as value
  #Value - list of beacons
  def summarize(values)
    result_hash = {}
    values.each { |value|
      value_hash = Hash[value.chars.group_by { |c| c }.map { |k, v| [k, v.size] }]
      result_hash.merge!(value_hash) { |k, v1, v2| v1+v2 }
    }
    Hash[result_hash.sort]
  end

  #Parsing runtime arguments and return hash in format {from: TIMESTAMP, to:TIMESTAMP}
  def parse_arguments
    options = {}

    option_parser = OptionParser.new do |opts|
      opts.banner = "Usage: bundler exec ruby main.rb [options]"
      opts.on('-f', '--from FROM_DATE_STRING', String, 'Summarize from specified date') do |date|
        options[:from] = date
      end
      opts.on('-t', '--to TO_DATE_STRING', String, 'Summarize until specified date') do |date|
        options[:to] = date
      end
      opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit
      end
    end

    begin
      option_parser.parse! ARGV
    rescue OptionParser::InvalidOption => e
      puts e
      puts option_parser
      exit 1
    end

    #for both 'to' and 'from' options
    utc_timestamps = options.collect { |k, v|
      date = v.downcase
      #checking keywords used in parameter
      words = date.split(' ')
      raise 'Incorrect date format' unless words.pop.eql?('ago')
      raise 'Incorrect date format' unless words.all? { |word| DATE_KEYWORDS.include?(word.pluralize) || word=~/\d+/ }

      #Converting string into timestamp
      time = Time.new
      words.each_slice(2) { |attr|
        raise 'Incorrect date format' unless attr[0]=~/\d+/
        raise 'Incorrect date format' unless attr[1]=~/[a-z]+/
        time = time.advance(attr[1].pluralize.to_sym => -attr[0].to_i)
      }
      [k, time.utc.to_i]
    }
    Hash[utc_timestamps]
  end

end


