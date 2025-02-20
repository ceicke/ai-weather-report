require 'httparty'
require 'json'
require 'fileutils'
require 'open-uri'
require 'open_meteo'
require 'openai'
require 'dotenv'
Dotenv.load

def save_image_to_disk(image_url, file_path)
  File.open(file_path, 'wb') do |file|
    file.write(HTTParty.get(image_url).parsed_response)
  end
end

def open_image(file_path)
  system("open #{file_path}")
end

def create_symlink(dir_path, file_path)
  FileUtils.copy_file(file_path, dir_path + '/current.png')
end

def fetch_weather_report
  location = OpenMeteo::Entities::Location.new(
    latitude: 53.5705.to_d, 
    longitude: 10.0329.to_d
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

weather_report_json = fetch_weather_report()

weather_report_prompt = <<-PROMPT
  Generate a written weather forecast for the next 24 hours out of this JSON from open metro API. It is an hourly forecast. Include a dedicated part for the current weather conditions:
  #{weather_report_json}
PROMPT

weather_report_response = openai_client.chat(
  parameters: {
    model: "gpt-4o",
    messages: [
      { 
        role: "user", 
        content: weather_report_prompt
      }
    ],
    temperature: 0.2,
  }
)

weather_report = weather_report_response.dig("choices", 0, "message", "content")

p weather_report

image_weather_prompt =  <<-IMAGEPROMPT
  Show the town of Hamburg, Germany in the picture, weather condition should be taken from the weather report that I give you. The background should change from left to right, depicting the changing weather over the day that is written in the weather forecast.
  Include a cat in the image wearing clothing which reflects what to wear outside in the current weather conditions. 
  The cat is a famous tv-presenter from the future who is presenting the weather-report live on-air right now. 
  Here comes the weather report:
  #{weather_report}
  Make it as realistic as possible and also super-dramatic, in black and white for an e-ink display. Do not include text.
IMAGEPROMPT

response = openai_client.images.generate(
  parameters: {
    prompt: image_weather_prompt,
    model: "dall-e-3",
    size: "1792x1024",
    quality: "standard",
  }
)
image_url = response.dig("data", 0, "url")

dir_path = 'output_images'
FileUtils.mkdir_p(dir_path)
file_path = "#{dir_path}/#{DateTime.now.to_s}.png"
save_image_to_disk(image_url, file_path)
create_symlink(dir_path, file_path)
#open_image(file_path)
