require 'httparty'
require 'json'
require 'fileutils'
require 'open-uri'
require 'open_meteo'
require 'openai'
require 'dotenv'
require 'pry'
require 'base64'
require 'optparse'
Dotenv.load

def save_image_to_disk(image_b64, file_path)
  File.open(file_path, 'wb') do |file|
    file.write(Base64.decode64(image_b64))
  end
end

def open_image(file_path)
  system("open #{file_path}")
end

def create_symlink(dir_path, file_path)
  FileUtils.copy_file(file_path, dir_path + '/current.png')
end

# Helper to read prompt templates from file and replace placeholders
def read_prompt_template(file_path, replacements = {})
  prompt = File.read(file_path)
  replacements.each do |key, value|
    prompt.gsub!("{{#{key}}}", value)
  end
  prompt
end

# Default values
options = {
  debug: false,
  open_image: false,
  temperature: 0.9, # Default temperature set to 0.9
  latitude: 53.5705, # Hamburg default
  longitude: 10.0329, # Hamburg default
  size: "1536x1024" # Default image size
}

OptionParser.new do |opts|
  opts.banner = "Usage: ruby weather.rb [options]"

  opts.on("--debug", "Enable debug output") do
    options[:debug] = true
  end

  opts.on("--[no-]open-image", "Open image after creation (default: no)") do |v|
    options[:open_image] = v
  end

  opts.on("--temperature TEMP", Float, "Temperature for OpenAI (default: 0.9)") do |v|
    options[:temperature] = v
  end

  opts.on("--lat LAT", Float, "Latitude (default: 53.5705 for Hamburg)") do |v|
    options[:latitude] = v
  end

  opts.on("--lon LON", Float, "Longitude (default: 10.0329 for Hamburg)") do |v|
    options[:longitude] = v
  end

  opts.on("--size SIZE", String, "Image size for output (default: 1536x1024)") do |v|
    options[:size] = v
  end
end.parse!

def fetch_weather_report(lat, lon)
  location = OpenMeteo::Entities::Location.new(
    latitude: lat.to_d, 
    longitude: lon.to_d
  )
  variables = { 
    current: %i[], 
    hourly: %i[temperature_2m,apparent_temperature,rain,showers,weather_code,cloud_cover,wind_speed_10m], 
    daily: %i[],
    timezone: 'Europe/Berlin',
  }
  
  return OpenMeteo::Forecast.new.get(location:, variables:).raw_json
end

api_key = ENV['OPENAI_KEY']

openai_client = OpenAI::Client.new(
  access_token: api_key,
  log_errors: true
)

weather_report_json = fetch_weather_report(options[:latitude], options[:longitude])

puts weather_report_json if options[:debug]

weather_report_prompt = read_prompt_template(
  File.join(__dir__, 'prompts', 'weather_report_prompt.txt'),
  { 'WEATHER_REPORT_JSON' => weather_report_json.to_s }
)

puts weather_report_prompt if options[:debug]

temperature = options[:temperature]

weather_report_response = openai_client.chat(
  parameters: {
    model: "gpt-4o",
    messages: [
      { 
        role: "user", 
        content: weather_report_prompt
      }
    ],
    temperature: temperature,
  }
)

weather_report = weather_report_response.dig("choices", 0, "message", "content")

puts weather_report if options[:debug]

animal_presenters = [
  "cat", "dog", "fox", "raccoon", "owl", "red panda", "hedgehog", "rabbit", "squirrel", "hamster", "frog", "parrot", "turtle", "chinchilla", "guinea pig", "ferret", "lizard", "snake", "goldfish", "mouse", "rat", "chameleon", "gecko", "axolotl", "octopus", "sea horse",
  "platypus", "kangaroo", "koala", "panda", "sloth", "lemur", "manatee", "narwhal", "dolphin", "whale", "penguin", "seal", "sea lion", "walrus"
]
todays_presenter = animal_presenters.sample

image_weather_prompt = read_prompt_template(
  File.join(__dir__, 'prompts', 'image_weather_prompt.txt'),
  {
    'PRESENTER' => todays_presenter,
    'WEATHER_REPORT' => weather_report
  }
)

response = openai_client.images.generate(
  parameters: {
    prompt: image_weather_prompt,
    model: "gpt-image-1",
    size: options[:size],
  }
)

image_b64 = response.dig("data", 0, "b64_json")

dir_path = 'output_images'
FileUtils.mkdir_p(dir_path)
file_path = "#{dir_path}/#{DateTime.now.to_s}.png"
save_image_to_disk(image_b64, file_path)
create_symlink(dir_path, file_path)
open_image(file_path) if options[:open_image]
