require 'rest-client'
require 'json'
require 'nokogiri'

url = 'http://folkets-lexikon.csc.kth.se/folkets/folkets/lookupword'

File.readlines('wordss.txt').each do |word|
  word.strip!
  payload = "7|0|6|http://folkets-lexikon.csc.kth.se/folkets/folkets/|1F6DF5ACEAE7CE88AACB1E5E4208A6EC|se.algoritmica.folkets.client.LookUpService|lookUpWord|se.algoritmica.folkets.client.LookUpRequest/1089007912|#{word}|1|2|3|4|1|5|5|1|0|0|6|"
  response = RestClient.post(url, payload, headers={content_type: 'text/x-gwt-rpc; charset=UTF-8'})

  if response.body.start_with?('//OK') then
    puts response.body
    result = JSON.parse(response.body[4..-1]).select { |ele| ele.kind_of? Array }[0][3..-2]
    next if result.nil?

    aggregated_result = "<definition>#{result.join('')}</definition>"

    File.write("out/#{word}.xml", Nokogiri::XML(aggregated_result).to_xml)
    puts '------------'
  else
    puts "Unable to find the definition of #{word}"
  end

end

