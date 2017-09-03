require 'rest-client'
require 'json'
require 'nokogiri'
require 'open-uri'

# char_map = {ä: '0344', å: '0345', 'ö': '0366'}
url = 'http://folkets-lexikon.csc.kth.se/folkets/folkets/lookupword'

def map_char(string)
  string.gsub('å', '0345').gsub('ö', '0366').gsub('ä', '0344').gsub(' ', '%20')
end

File.readlines('in/word-list.txt').each do |word|
  word.strip!
  payload = "7|0|6|http://folkets-lexikon.csc.kth.se/folkets/folkets/|1F6DF5ACEAE7CE88AACB1E5E4208A6EC|se.algoritmica.folkets.client.LookUpService|lookUpWord|se.algoritmica.folkets.client.LookUpRequest/1089007912|#{word}|1|2|3|4|1|5|5|1|0|0|6|"
  response = RestClient.post(url, payload, headers={content_type: 'text/x-gwt-rpc; charset=UTF-8'})

  if response.body.start_with?('//OK') then
    puts "#{word} => #{response.body}"
    result = JSON.parse(response.body[4..-1]).select { |ele| ele.kind_of? Array }[0][3..-2]
    next if result.nil?

    result.each do |meaning|
      sound_file = Nokogiri::XML(meaning).at('phonetic')&.attribute('soundFile').to_s
      next if sound_file.empty?

      remote_url = "http://lexin.nada.kth.se/sound/#{map_char(sound_file)}"
      local_name = "sound/#{sound_file}"
      #next if File.file?(local_name)

      puts "Downloading #{remote_url}"
      open(local_name, 'wb') do |file|
        begin
          file << open(remote_url).read
        rescue Exception => e
          retry if e.kind_of? Net::OpenTimeout
        end
      end
    end

    aggregated_result = "<definition>#{result.join('')}</definition>"

    File.write("out/#{word}.xml", Nokogiri::XML(aggregated_result).to_xml)
    puts '------------'
  else
    puts "Unable to find the definition of #{word}"
  end
end

puts 'Done!'
