require_relative 'summarize_beacon'
begin
  summarize = SummarizeBeacon.new
  params = summarize.parse_arguments()
  values = summarize.get_values(params)
  summarize.summarize(values).each {|k,v| puts "#{k},#{v}" }

rescue RestClient::Exception => e
  puts 'Cannot connect to REST service:'
  puts e.message
  exit(2)
rescue REXML::ParseException => e
  puts 'Cannot parse response XML:'
  puts e.message
  exit(3)
end
