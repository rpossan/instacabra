require 'capybara/poltergeist'
module Drivers
	class Poltergeist

		def initialize
			Capybara.javascript_driver = :poltergeist
	        Capybara.default_driver = :poltergeist
	        Capybara.default_max_wait_time = 10

	        Capybara.register_driver :poltergeist do |app|
	        	Capybara::Poltergeist::Driver.new(
	        		app,
	        		{
	        			debug: false,
						js_errors: false,
						timeout: 180,
						phantomjs_options:
							[
								'--load-images=no',
								'--ignore-ssl-errors=yes',
								'--ssl-protocol=any'
							]
	        		}
				)
			end
		end

		def session
			Capybara::Session.new(:poltergeist)
		end
	end
end