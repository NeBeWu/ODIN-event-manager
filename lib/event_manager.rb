require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone_number(phone_number)
  phone_number.gsub!(/[^\d]/, '')

  return phone_number[-10, 10] if phone_number.length == 10 ||
                                  phone_number.length == 11 &&
                                  phone_number.start_with?('1')

  '0000000000'
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def extract_hour(date)
  Time.strptime(date, '%m/%d/%y %H:%M').hour
end

def max_keys(hash)
  max = hash.max { |pair1, pair2| pair1[1] <=> pair2[1] }[1]
  hash.select! { |key, value| value == max }
  hash.keys
end

def time_target(csv_content)
  registration_hours = {}

  csv_content.each do |row|
    hour = extract_hour(row[:regdate])
    registration_hours[hour].nil? ? registration_hours[hour] = 1 : registration_hours[hour] += 1
  end

  puts "The peak registration hours are:"
  puts max_keys(registration_hours)
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv', 
  headers: true,
  header_converters: :symbol
)

time_target(contents)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  #legislators = legislators_by_zipcode(zipcode)

  #form_letter = erb_template.result(binding)

  #save_thank_you_letter(id, form_letter)
end
