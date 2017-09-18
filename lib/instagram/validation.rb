module Validation

	def self.validate_location(location)
		raise "Location ID is null!" if location.id.nil?
		raise "Location ID as #{location.id.class} is invalid! Only Fixnum is allowed as param." if location.id.class != Fixnum
		true
	end

	def self.validate_user(profile)
		raise "Username is empty!" if profile.user.nil?
		true
	end

	def self.validate_html_content(profile)
		raise "Profile is not fetched!" if profile.html_content.nil?
		true
	end

	def self.validate_permission(profile)
		if profile.class == Instagram::Profile && profile.is_private? 
			raise "Profile is private! Is not possible to fetch media. You can try to log in to fetch data."
		end
		true
	end

end