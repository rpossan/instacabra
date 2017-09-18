require 'instagram/media'

module Instagram
	class Location < Instagram::Media

		attr_accessor :shared_data, :id, :name, :slug, :has_public_page, :latitude, :longitude, :media_count

		def initialize(id = nil)
			@id = id
			@session ||= Drivers::Base.initialize_driver Instagram::Ripper::DEFAULT_DRIVER
			fetch! unless id.nil?
		end

		def close_connection!
			@session.driver.quit
		end

		def media
			@media
		end

		def compact
			self.id.nil? ? {} :
			{ latitude: self.latitude, name: self.name, longitude: self.longitude, id: self.id }
		end

		def html_content
			@html_content
		end

		def fetch!
			validate_location self.id
			@media = []
			location_uri = "#{Instagram::Ripper::INSTAGRAM_URI}explore/locations/#{self.id}"

			@html_content = Nokogiri::HTML(open(
				location_uri,
				'User-Agent' => Instagram::Ripper::USER_AGENT,
				'read_timeout' => Instagram::Ripper::READ_TIMEOUT
			))

			self.shared_data = fetch_shared_data @html_content
			self.media_count = Instagram::Ripper::DEFAULT_MEDIA_LIMIT #Locations has no total media count
			self.latitude = @html_content.xpath('//meta[@property="place:location:latitude"]/@content').text
			self.longitude = @html_content.xpath('//meta[@property="place:location:longitude"]/@content').text
			self.has_public_page = self.shared_data['has_public_page']
			self.slug = self.shared_data['slug']
			self.name = self.shared_data['name']
		end

		def configure_driver(driver = :selenium)
			@session = initialize_driver(driver)
		end

		private

		def fetch_shared_data(page)
			js = page.content.match('window._sharedData = .*')
			js = js.to_s.gsub("window._sharedData = ", "").chop
			json_content = JSON.parse(js)
			json_content = json_content['entry_data']['LocationsPage'][0]['location']
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