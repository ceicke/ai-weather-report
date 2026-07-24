# AI Weather Report

A Ruby CLI tool that generates a written weather forecast and a matching AI-generated image for a given location and time, using Open-Meteo for weather data and OpenAI for text and image generation. The image features a randomly chosen animal TV presenter reporting the weather in Hamburg (or any location you specify).

## Features
- Fetches hourly weather data from Open-Meteo for any latitude/longitude (default: Hamburg, Germany)
- Generates a concise, informative weather report using OpenAI GPT-4o
- Creates a high-contrast, black-and-white image for e-ink displays, showing the weather and a stylish animal presenter
- Saves the image to `output_images/` and updates a symlink to the latest image
- CLI switches for debug, temperature, location, image size, and auto-opening the image

## Setup

### Prerequisites
- Ruby (>= 3.0 recommended)
- Bundler (`gem install bundler`)
- OpenAI API key (for text and image generation)
- Open-Meteo Ruby client (installed via Bundler)

### Installation
1. Clone the repository:
   ```sh
   git clone https://github.com/ceicke/ai-weather-report.git
   cd ai-weather-report
   ```
2. Install dependencies:
   ```sh
   bundle install
   ```
3. Create a `.env` file in the project root and add your OpenAI API key:
   ```env
   OPENAI_KEY=sk-...
   ```

## Usage

Run the script with Ruby:
```sh
ruby weather.rb [options]
```

### Options
- `--debug`                Enable debug output (prints weather JSON and prompts)
- `--[no-]open-image`      Open the generated image after creation (default: no)
- `--temperature TEMP`     Set OpenAI temperature (default: 0.9)
- `--lat LAT`              Latitude for weather data (default: 53.5705 for Hamburg)
- `--lon LON`              Longitude for weather data (default: 10.0329 for Hamburg)
- `--size SIZE`            Image size for output (default: 1536x1024)
- `--location LOCATION`    Location name; uses `prompts/<location>.txt` as the image prompt (default: hamburg)

Example:
```sh
ruby weather.rb --debug --open-image --lat 53.3167 --lon 12.8333 --size 1024x1024 --location havelberge
```

To add a new location, create a `prompts/<location>.txt` file containing the full image
prompt for that place (see `prompts/hamburg.txt` for reference). Customize the scene freely —
e.g. city architecture vs. nature. The `{{PRESENTER}}` and `{{WEATHER_REPORT}}` placeholders are
filled in by the script. The shared `prompts/weather_report_prompt.txt` (the written forecast)
uses the capitalized `--location` value for its `{{LOCATION}}`. Coordinates are still passed
separately via `--lat`/`--lon`.

## Output
- Images are saved in the `output_images/` directory with a `<location>_<timestamp>.png` filename.
- The latest image per location is also available as `output_images/current_<location>.png` (e.g. `current_hamburg.png`).

## Project Structure
- `weather.rb`                Main CLI script
- `prompts/`                  Contains prompt templates for text and image generation
- `output_images/`            Output directory for generated images
- `.env`                      Your OpenAI API key (not checked in)

## License

MIT License

Copyright (c) 2025 Christoph Eicke

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
