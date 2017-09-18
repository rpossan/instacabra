# InstaCabra

[![N|Solid](logo.png)]()

It's a Ruby gem to rip Instagram data such as posts, images, videos or users profiles info.There is also a user interface to fetch this data. This article provides the context bellow:

  - Gem documantation, features and How-To
  - User Interface and Architecture
  - Examples and how-tos
 
# Table of Contents
1. [Gem](#Gem)
1.1 [Basics](#basics)
1.2 [Drivers](drivers)
1.3 [Setup](#setup)
1.4 [Ripping a profile](ripping)
1.5 [Filtering profiles to be ripped](filtering)
1.6 [API Reference and Documentation](#api)
2. [Ripper-UI - User Interface Application](#ui)
3. [Support](#support)


## 1 Gem
The gem was developed to fetch data from Instagram webpage through web crawler using Capybara to manipulate the page and PhantomJs to execute in background and headless.
The gem depends on the bellow gems:

| Gem   |      Purpose      |
|----------|:-------------:
| byebug |  Debugging and tests |
| capybara |    Simulates users interaction with the webpage   |
| nokogiri | Fetch and parse HTML code from pages |
| open-uri | Http requests from web  |
| poltergeist | A PhantomJS driver for Capybara |
| PhantomJS | A external driver to run tests headless |

* Optionally is possible to use other drives like Chromedriver, IEDriver, etc.

## 1.1 Basics
It has the simple gem skeleton where the main code stay in lib diretory.
Drivers folder has the drivers to manipulate webpage interactions.
Instagram folder has the main classes and modules.
Ripper folder has the gem version file.
**Ripper.rb**: Main module responsible to setup and prepare gem how to fetch data.
**Instagram.json**: The main output file to get as example when data is extracted.
**Location.rb**: This module parse data from a location profile.
**Profile.rb**: This module parse data from an users profile.
**Media.rb**: Is the core module to get data from both user and location profile. It is responsible to build structure, navigate pages, extract data, parse html codes and generate outputs.

The gem can be used locally installing through the bundler or starting th console mode of gem.

##### Bundle Installation:
```sh
$ bundle install [PATH TO GEM]
$ irb
$ require 'instagram-ripper'
#code
```
##### Console Mode:
```sh
$ cd [PATH TO GEM]
$ bin/console
#code
```
## 1.2 Drivers
The gem allow to run processes into a browser like a Chrome, Internet Explorer or Firefox. But native it runs headless (without a browser, only commands) with the software PhantomJS.
Initially the gem provides support to Mozillla Selenium webdriver and Poltergeist (headless) driver.
If you want to run through other browsers like Chrome or internet Explorer, you need to implement and extend a new module.
New modules are in the folder **lib/drivers**. Base.rb is the main module and it has the method **initialize_driver(driver)** where param is the symbol of your desired driver.
To implement new driver, you can copy other modules and renames files and module name to your desired name so, on initialize methdos, define your driver setup.

## 1.3 Setup
The main configuration is the module Ripper (lib/instagram/ripper.rb).
In this module, you can set up the bellow constants:
**INSTAGRAM_URI**: The base Instagram URL. Default: https://instagram.com/
**DEFAULT_DRIVER**: Driver responsible to run automation scripts on the webpages. Default is poltergeist to run headless (without a browser) and to be more performatic. If you want to see what is happening during the execution, run with a browser driver. The gem has implemented Selenium Firefox browser to test scripts. Change this value to :selenium to see web navigation. If you desire to run another browsers, implement a new module and configure you driver.
**DEFAULT_MEDIA_LIMIT**: Limit of media to be ripped. Default is 30 but actually has no limit, as client required. It is important to se a limit because with no limits the process can last long and kill all the process.
**USER_AGENT**: User agent to be used and simulated when the gem navigates on web. Some web pages block IPs when it requires many requests on the page. Using an agent it simulates a real user and avoid to be blocked. Default vaue is: "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.87 Safari/537.36". Feel free to use any agent.
**READ_TIMEOUT**:  Limit time to wait page to respond, used for Nokogiri.Default is 5 seconds.
#### Methods
##### authenticate (username, password)
Method to authenticate an user to Instagram passing string of username and password. It is usefull to private profiles that requer authentication on Instagram. Caution: It does not work if the profile that your trying to fetch has not auhotized logged user on gem session.
##### configure_driver (:symbol)
Pass a symbol representative of a driver you want to configure. The module driver has to be implemented. This method can be utilized during a fetch process.

## Setting up a Profile
Before start to rip an Instagram Profile, you need to initialize a new object. It can be an User or Location Profile. In case of Location profile the param may be an integer represanting ID identificator of the location.

```ruby
user = Instagram::Profile.new "rpossan"
# Or Location Profile
location = Instagram::Location.new 012345678
```
This return a new object with all profile data. It has no media data like posts.

## 1.4 Ripping posts from a Profile
Having a variable with an user or location profile, you can fetch media like video, photo or both.
To do this a profile has 3 main methods to fetch data: **fetch_media,fetch_videos, fetch_photos**. Fetching all type of post, fetching only videos posts or only photos posts.
Example:
```ruby
profile.fetch_media # Fetch all kind of media
profile.fetch_photos # Fetch all photos from profile
profile.fetch_videos # Fetch all videos from profile
```
##### Fetching with limit
You can limit the quantity of posts to be fetched passing a integer value as parameter.

```ruby
profile.fetch_media 10
profile.fetch_photos 2000
profile.fetch_videos 9999
```

##### Fetching in intersection
You can fetch data in tersection from initial value until desired. But it no includes filtered posts. If you fetch videos, but in the intersection has only 2 posts of videos, your return array will have only 2 posts, not until fetch 10 videos.
This feature is useful to paginate and fetch posts in batch. But it affects the performance of ripping process because, eg. to fetch 200..1000, the automated script will navigate until find the 200 post. It consumes the network and can be influented.

```ruby
profile.fetch_media 0..10 # Fetch media from last post until 10 ago.
profile.fetch_videos 10..20 # Fetch videos from 10 until 20 posts.
profile.fetch_photos -20..50 # Fetch from 0 until 50.
```
## 1.5 Filtering posts to be ripped
The gem has parameters to be configured then it filters posts to be fetched.
Actually has 2 valid parameters to be passed on method fetch (fetch_media, fetch_photos or fetch_videos). The parameters to be passed may be a hash of key and values.
**has_location**: It filters if post has or not location tagged.The value can be a boolean value true | false. For default it is false, fetching all kind of posts. If you pass true, only store posts with location tagged to be extraced.When you use it in a location profile, it will fetchh all posts because all posts of a location profile has location tagged (own location).
**from**: This parameter represents a unix timestamp to be fetched from. Default is 0. If you pass a integer as th parameter, gem will fetch data only posts after this timestamp.
Examples of use:

```ruby
# Fetch only posts with location tagged from last post until 200
profile.fetch_photos 0..200, { has_location: true }

# If is a Location profile, it is useless. All posts of location profile is tagged.
location_profile.fetch_media 0..200, { has_location: true }

# Fetch posts from 20/02 until now.
profile.fetch_photos 0..200, { from: 1487616668 }

# It is the same withou the parameter. Will navigate all posts.
profile.fetch_videos 0..200, { from: 0 }

# Fetch all posts from 20/02 until now that has location tagged.
profile.fetch_media 50..50, { has_location: true, from: 1487616668 }
```
## 1.5 API Reference and Documantation

### Drivers::Base
#### initialize_driver([symbol])
Initialize a new session of driver for the main module Ripper

### Drivers::Poltergeist
##### initialize
Set up the initialization session for Poltergeist driver to object. It requires PhantomJS installed on environment.
##### session
Return a new session object of Poltergeist.

### Drivers::Selenium
##### initialize
Set up the initialization session for Selenium driver to object. It requires Selenium driver installed on environment.
##### session
Return a new session object of Selenium webdriver.

### Instagram::Profile
##### initialize(String)
String value represanting username profile. It can be nil and it returns a Profile object.
##### get_class
Return kind of class of object. Profile or Location..
##### html_content
Return the html content (code) of profile fetched.
##### is_private?
Return a boolean represanting if profile is private or not.
##### fetch!
Rip html content of profile of instanced object. It is not the posts of a profile, it is profile data.
##### configure_driver(symbol)
Configure or reconfigure a new session driver.

### Instagram::Location
##### initialize(integer)
Optional parameter integer representing the ID identificator of a location. It returns a new Location object.
##### close_connection!
Quit and close connection with webdriver.
##### media
Returns media object of profile.
##### compact
Return a compacted hash of location attributes.
##### html_content
Returns html content of Location profile.
##### fetch!
Fetch profile data for Location.
##### configure_driver(symbol)
Configure or reconfigure a new session with webdriver.

### Instagram::Media
##### extract_media
Return an array only with media attributes of object.
##### extract
Return an array with the given json format. It has the header of json and media data. To convert the return in an explicit json, you canuse the method **.to_json**.
##### build!
Parse html fetched to object structure.
##### is_video?
Returns true if is a post of video or false.
##### is_profile?
Returns true if is an user profile or false.
##### is_location?
Returns true if is a location profile or false.
##### identifier
Returns main identificator of profile.If is user profile, returns the username.If is location, returns a number of ID.
##### fetch_videos
Fetch only posts of videos from an user or location. It can be parametrized.
##### fetch_photos
Fetch only posts of photos from an user or location. It can be parametrized.
##### fetch_media
Fetch all kind of posts both user or location. It can be parametrized.
##### is_valid?
Validates media from a profile.
##### fetch_usertags
Returns tags tagged on post
##### load_scrolling
Scrolls windows until final of loaded html.
##### fetch_media_by_index(index)
Get data from a post by an integer index. If it was not loaded, you have to scroll until the index of post shows.
##### load_more
It triggers the click on button "Load more". It is required on the first time because the segment is through the infinite scroll of page.
##### loaded_media
Returns the size of loaded media until the moment.
##### set_limit
Set logical limit for fetching posts.
##### set_offset
Set logical offset for fetching posts.

### Instagram::Validation
##### validate_location(Location)
Validates if ID of location object is null or invalid value.
##### validate_user(string)
Validate if username is empty.
##### validate_html_content(Profile)
Validates if profile has content. If not fetched, will raise an validation error.
##### validate_permission(profile)
Validates if profiles is private or has not permission to view your posts.


## 2.0 Ripper-UI - User Interface Application

It is the user interface application to run most gem features as user friendly. It is a Ruby On Rails application that uses the gem locally.
You can set the gem on Gemfile passing the path to gem directory.
This application requires:
* SQLite3: to store data
* Sidekiq: for background jobs
* Redis Server: for sidekiq jobs


## 3.0 Support
Both gem and ui application was developed by Ronaldo Possan. Feel free to contact me for support doubts, help, architecture or consult bugs:
@rpossan or ronaldo.possan@gmail.com
I will not mantain more gem and ui application.
