require 'nokogiri'
require 'byebug'
require 'drivers/base'
require 'instagram/validation'
require 'open-uri'

module Instagram
	
	class Media
		attr_accessor :shared_data, :display_src, :video_url, :code, :usertags, :id, :caption,
		:likes_count, :is_video, :location, :date, :type

		def extract_data
			data_arr = []
			self.media.each do |m|
				data = {
					attribution: nil,
					tags: m.usertags,
					type: (m.is_video? ? "video" : "image"),
					location: (m.location.nil? ? {} : m.location.compact),
					comments: { count: 0, data: [] },
					filter: "Normal",
					created_time: m.date.to_s,
					link: "https://www.instagram.com/p/#{m.code}",
					video_url: m.video_url,
					likes: { count: m.likes_count, data: [] },
					images: {
						low_resolution: {
							url: m.display_src,
							width: 320,
							height: 320
						},
						thumbnail: {
							url: m.display_src,
							width: 150,
							height: 150
						},
						standard_resolution: {
							url: m.display_src,
							width: 640,
							height: 640
						}
					},
					users_in_photo: [],
					caption: {
						created_time: m.date.to_s,
						text: m.caption,
						from: {
							username: is_location? ? self.name : self.username,
							profile_picture: is_location? ? "" : self.profile_pic_url,
							id: self.id,
							full_name: is_location? ? self.name : self.full_name
						},
						id: ""
					},
					user_has_liked: nil,
					id: nil,
					user: {
						username: is_location? ? self.name : self.username,
						profile_picture: is_location? ? "" : self.profile_pic_url,
						id: self.id,
						full_name: is_location? ? self.name : self.full_name,
						biography: is_location? ? "" : self.biography
					}
				}

				data_arr << data
			end
			return data_arr
		end

		def extract
			struct = {
				pagination: { next_url: "", next_max_id: "" },
				meta: {code: 200},
				data: []
			}

			self.extract_data.each {|data| struct[:data] << data }

			return struct # It is not JSON. Use .to_json to convert
		end

		def build!
			json_location = self.shared_data['location']
			self.is_video = self.shared_data['is_video']
			self.display_src = self.shared_data['display_src']
			self.video_url = self.shared_data['video_url'].to_s
			self.code = self.shared_data['code']
			self.id = self.shared_data['id']
			self.caption = self.shared_data['caption']
			self.likes_count = self.shared_data['likes']['count']
			self.date = self.shared_data['date']
			self.location =  Location.new json_location['id'].to_i if is_profile? && !json_location.nil?
			self.usertags = fetch_usertags
		end

		def media
			@media
		end

		def is_video?
			self.is_video
		end

		def is_profile?
			self.type == Instagram::Profile
		end

		def is_location?
			self.type == Instagram::Location
		end

		def identifier
			if is_location?
			 	param = self.id
			elsif is_profile?
				param = self.username
			end
			return param.to_s
		end

		def fetch_videos(param = Instagram::Ripper::DEFAULT_MEDIA_LIMIT, options = {})
			options[:type] = :video
			fetch_media(param, options)
		end

		def fetch_photos(param = Instagram::Ripper::DEFAULT_MEDIA_LIMIT, options = {})
			options[:type] = :photo
			fetch_media(param, options)
		end

		def fetch_media(param = Instagram::Ripper::DEFAULT_MEDIA_LIMIT, options = {})
			
			@session ||= Drivers::Base.initialize_driver Instagram::Ripper::DEFAULT_DRIVER

			from_param = 0
			from_param = options[:from].to_i unless options[:from].nil?

			self.type = self.class

			options[:has_location] = false if is_location?

			@media = []

			uri = Instagram::Ripper::INSTAGRAM_URI
			uri = "#{uri}explore/locations/" if is_location?

			@session.visit uri + identifier

			validate_html_content
			validate_permission

			load_more if @session.has_link? 'Load more'

			limit = set_limit param
			offset = set_offset param

			to_fetch = offset + limit

			to_fetch = ((limit < loaded_media) ? limit : loaded_media)

			media_fetched = 0
		
			1.upto(limit) do |idx|
				if idx >= offset
					current_media = fetch_media_by_index(idx-1)
					if !current_media.nil? && current_media.is_valid?(options)
						break if (from_param > 0 && from_param >= current_media.date.to_i)
						@media << current_media 
					end
				end
				load_scrolling if (idx % 10) == 0
			end

			#@session.driver.quit
			true
		end

		def is_valid? options
			has_location, only_videos, only_photos = false, false, false
			has_location = true if options[:has_location] == true
			only_videos = true if options[:type] == :video
			only_photos = true if options[:type] == :photo
			r = true

			if (has_location && self.location.nil?)
				r = false
			elsif (only_videos && !self.is_video?)
				r = false
			elsif (only_photos && self.is_video?)
				r = false
			end

			return r
		end

		private

		def fetch_usertags
			usertags = []
			self.shared_data['usertags']['nodes'].each do |tag|
				usertags << tag['user']['username']
			end
		end

		def load_scrolling
			@session.execute_script('window.scrollTo(0,document.body.scrollHeight)')
			sleep 2
			@html_content = Nokogiri::HTML(@session.body)
		end

		def fetch_media_by_index(idx)
			begin
				@session.all('div', class: '_ovg3g')[idx].trigger('click')

				sleep 2

				post = Nokogiri::HTML(open(
					@session.current_url,
					'User-Agent' => Instagram::Ripper::USER_AGENT,
					'read_timeout' => Instagram::Ripper::READ_TIMEOUT
				))

				js = post.content.match('window._sharedData = .*')
				js = js.to_s.gsub("window._sharedData = ", "").chop
				json_content = JSON.parse(js)
				json_content = json_content['entry_data']['PostPage'][0]['media']
				media = Instagram::Media.new
				media.shared_data = json_content
				media.type = self.class
				media.build!
				
				@session.click_button "Close"
				sleep 1

				return media
			rescue => error
				#@session.driver.quit
				puts "An error occurred when try to fetch media <#{idx}> ! Try again.\n" 
				#raise error
			end
		end

		def load_more
			@session.click_link 'Load more'
			sleep 1
			@html_content = Nokogiri::HTML(@session.body)
		end

		def loaded_media
			html_content.xpath("//img[@class='_icyx7']").size
		end

		def set_limit(param)
			configured_limit = param.last if param.class == Range
			configured_limit = param.to_i if param.class == Fixnum
			configured_limit = media_count if configured_limit >= media_count
			return configured_limit
		end

		def set_offset(param)
			r = (param.class == Range) ? param.first.to_i : 1
			r = 1 if r < 1
			return r
		end

	end
end