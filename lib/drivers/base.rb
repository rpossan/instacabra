require 'capybara'
require 'drivers/selenium'
require 'drivers/poltergeist'

module Drivers

	class Base

		def self.initialize_driver(driver)
			send("setup_#{driver}")
		end

		private
		def self.setup_poltergeist
			Drivers::Poltergeist.new.session
		end

		def self.setup_selenium
			Drivers::Selenium.new.session
		end

	end

end