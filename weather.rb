require 'httparty'
require 'json'
require 'fileutils'
require 'open-uri'
require 'open_meteo'
require 'openai'
require 'dotenv'
require 'pry'
require 'base64'
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
Generate a written weather forecast for Hamburg, Germany for the next 24 hours based on this hourly data from the Open-Meteo API. 

Please include:
- Current conditions (temperature, cloud cover, wind, and any precipitation)
- Temperature trend throughout the day (high/low, when to expect changes)
- Precipitation forecast (timing and intensity if any)
- Wind conditions (speed changes and significant patterns)
- Cloud cover patterns
- A brief outlook for tomorrow

Make the report concise but informative, highlighting any notable weather changes.
When interpreting weather codes, note that:
- Codes 0-3 represent clear to partly cloudy
- Codes 45-49 represent fog conditions
- Codes 51-67 represent different intensities of rain
- Codes 71-77 represent snow
- Codes 80-82 represent rain showers

Here's the weather data:
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

animal_presenters = [
  "cat", "dog", "fox", "raccoon", "owl", "red panda", "hedgehog", "rabbit", "squirrel", "hamster"
]
todays_presenter = animal_presenters.sample

image_weather_prompt =  <<-IMAGEPROMPT
Show the city of Hamburg, Germany with weather conditions based on the provided forecast. Only show rain in portions of the image if it's the dominant weather pattern for a significant part of the day - don't overemphasize precipitation unless it's the main feature of the forecast.
The background should transition from left to right showing the changing weather throughout the day, giving proportional space to each weather condition based on its duration in the forecast, include the approximate time of each condition in 24h format.
In the foreground, include a fashionable #{todays_presenter} TV presenter wearing clothing appropriate for the current weather conditions. The #{todays_presenter} should be reporting live, with professional poise and dramatic flair.
Even if cloudy or rainy conditions are mentioned, maintain some contrast and visual clarity in the image. Show Hamburg's iconic architecture regardless of weather.
If possible, include the temperatures for the different weather conditions as degrees celsius, and the wind speed in km/h.
The image should be realistic yet dramatic, rendered in high-contrast black and white for an e-ink display.
Weather forecast details:
#{weather_report}
IMAGEPROMPT

response = openai_client.images.generate(
  parameters: {
    prompt: image_weather_prompt,
    model: "gpt-image-1", # Neues Modell für Bildgenerierung
    size: "1536x1024",
    #quality: "high",
    # style: "vivid", # Optional: siehe OpenAI-Doku
    # response_format: "url" # Standard ist "url"
  }
)

image_b64 = response.dig("data", 0, "b64_json")

dir_path = 'output_images'
FileUtils.mkdir_p(dir_path)
file_path = "#{dir_path}/#{DateTime.now.to_s}.png"
save_image_to_disk(image_b64, file_path)
create_symlink(dir_path, file_path)
open_image(file_path)
