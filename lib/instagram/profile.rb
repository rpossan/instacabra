require 'instagram/media'
module Instagram

	class Profile < Instagram::Media

		attr_accessor :user, :profile_pic_url, :id, :media_count, :external_url, :biography,
		:username, :full_name

		@session = nil

		def initialize(user = nil)
			@user = user
			fetch! unless user.nil?
		end

		def close_connection!
			@session.driver.quit
		end

		def get_class
			self.class
		end

		def html_content
			@html_content
		end

		def is_private?
			shared_data['is_private']
		end

		def fetch!
			validate_user
			@media = []
			profile_uri = Instagram::Ripper::INSTAGRAM_URI + self.user
			
			@html_content = Nokogiri::HTML(open(
				profile_uri,
				'User-Agent' => Instagram::Ripper::USER_AGENT,
				'read_timeout' => Instagram::Ripper::READ_TIMEOUT
			))

			self.shared_data = fetch_shared_data @html_content
			self.profile_pic_url = shared_data['profile_pic_url']
			self.id = shared_data['id']
			self.media_count = shared_data['media']['count']
			self.external_url = shared_data['external_url']
			self.biography = shared_data['biography']
			self.username = shared_data['username']
			self.full_name = shared_data['full_name']
			self
		end

		def configure_driver(driver = :selenium)
			@session = initialize_driver(driver)
		end

		private

		def fetch_shared_data(page)
			validate_html_content
			js = page.content.match('window._sharedData = .*')
			js = js.to_s.gsub("window._sharedData = ", "").chop
			json_content = JSON.parse(js)
			json_content['entry_data']['ProfilePage'][0]['user']
		end

		def method_missing(method_sym, *arguments, &block)
			if method_sym.to_s =~ /^validate_(.*)$/
				validate($1.to_s)
			else
				super
			end
		end

		def validate(type)
			Validation.send "validate_#{type}", self
		end

	end

end