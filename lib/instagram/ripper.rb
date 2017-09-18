require 'instagram/ripper/version'
require 'capybara'
require 'capybara/poltergeist'
require 'nokogiri'
require 'open-uri'
require 'instagram/profile'
require 'instagram/media'
require 'instagram/location'
require 'instagram/validation'
require 'drivers/base'
require 'byebug'

# Instagram::Ripper
# @author Ricardo Ichizo <ricardo.ichizo [at] gmail [dot] com>
module Instagram
  
  module Ripper

    @driver = Drivers::Base.new

    # Instagram site
    INSTAGRAM_URI = 'https://instagram.com/'
    
    # Default driver to run. Options: :selenium (chrome) | :poltergeist (headless)
    DEFAULT_DRIVER = :poltergeist

    # Default quantity of media to retrieve
    DEFAULT_MEDIA_LIMIT = 30

    USER_AGENT = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.87 Safari/537.36"
    READ_TIMEOUT = "5"

    # Authenticate against the Instagram service.
    #
    # @param username [String] the username to authenticate against the Instagram service
    # @param password [String] the password to authenticate against the Instagram service
    # @return session [Capybara::Session]
    def self.authenticate(username, password)
      @session = @driver.initialize_driver(DEFAULT_DRIVER)
      @session.visit INSTAGRAM_URI
      @session.click_link 'Log in'
      @session.fill_in 'Username', :with => username
      @session.fill_in 'Password', :with => password
      #@session.find_button('Log in').trigger('click')
      @session.click_button 'Log in'
      @session
    end

    def self.configure_driver(driver = :selenium)
      @session = initialize_driver(driver)
    end

  end
end
