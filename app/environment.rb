# environment.rb
# 
# This file is where you should load all of your dependencies and 
# do any global environment setup (e.g. Dotenv.load)

require 'rubygems' 
require 'bundler/setup'
# require all of the gems in the gemfile
Bundler.require
# require any non-gem libraries that are needed
require 'net/https'
require 'erb'
require 'csv'
require 'date'
# require all of the app's models
require_all './models'
# set the app root
set :root, File.expand_path("../../", __FILE__)
# load the environment variables from .env (testing environment)
Dotenv.load
# load the config from config.rb
require './app/config'

# Session:Cookie needed by OmniAuth
use Rack::Session::Cookie, :expire_after => 1209600, # 7 days
                           :secret => ENV['COOKIE_SECRET']

# MethodOverride for RESTful interface
use Rack::MethodOverride


# Database provided by sqlite3 in development and postgresql on Heroku
db = URI.parse(ENV['DATABASE_URL'])

ActiveRecord::Base.establish_connection(
  :adapter  => db.scheme == 'postgres' ? 'postgresql' : db.scheme,
  :host     => db.host,
  :port     => db.port,
  :user_name => db.user,
  :password => db.password,
  :database => db.path[1..-1],
  :encoding => 'utf8'
)

# Mail.defaults do
#   delivery_method :smtp, { :address              => "smtp.gmail.com",
#                            :port                 => 587,
#                            :domain               => 'localhost.localdomain',
#                            :user_name            => ENV['GMAIL_ACCOUNT'],
#                            :password             => ENV['GMAIL_PASSWORD'],
#                            :authentication       => 'plain',
#                            :enable_starttls_auto => true  }
# end

Mail.defaults do
  delivery_method :smtp, {
    :port      => 587,
    :address   => "smtp.mandrillapp.com",
    :user_name => ENV["MANDRILL_USERNAME"],
    :password  => ENV["MANDRILL_API_KEY"],
    :enable_starttls_auto => true,
  }
end

# Pony.options = {
#     from: "SAAB Contact Form <#{ENV['GMAIL_ACCOUNT']}>",
#     :via => :smtp,
#     :via_options => {
#         :address              => 'smtp.gmail.com',
#         :port                 => '587',
#         :enable_starttls_auto => true,
#         :user_name            => ENV['GMAIL_ACCOUNT'],
#         :password             => ENV['GMAIL_PASSWORD'],
#         :authentication       => :plain, # :plain, :login, :cram_md5, no auth by default
#         :domain               => "localhost.localdomain" # the HELO domain provided by the client to the server
#     }
# }