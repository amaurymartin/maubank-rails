# frozen_string_literal: true

source 'https://rubygems.org'

ruby '3.3.3'

gem 'bcrypt', '~> 3.1.7'
gem 'bootsnap', require: false
gem 'cpf_cnpj'
gem 'dotenv-rails'
# gem 'image_processing', '~> 1.2'
gem 'jbuilder'
# gem 'kredis'
gem 'pg', '~> 1.1'
gem 'puma', '>= 5.0'
# gem 'rack-cors'
gem 'rails', '~> 7.1.3', '>= 7.1.3.4'
# gem 'redis', '>= 4.0.1'
gem 'root_domain'
gem 'validators'

group :development, :test do
  gem 'debug', platforms: %i[mri windows]
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'rspec-rails'
end

group :development do
  gem 'annotate', require: false
  gem 'rubocop', require: false
  gem 'rubocop-factory_bot', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rspec', require: false
  gem 'rubocop-rspec_rails', require: false
  # gem 'spring'
end

group :test do
  gem 'simplecov', require: false
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[windows jruby]
