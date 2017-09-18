module Drivers
	class Selenium

		def initialize
	        Capybara.default_driver = :selenium
	        Capybara.default_max_wait_time = 10
	        Capybara.register_driver :selenium do |app|
	          Capybara::Selenium::Driver.new(app, {:browser => :chrome})
	        end
		end

		def session
			Capybara::Session.new(:selenium)
		end

	end
end