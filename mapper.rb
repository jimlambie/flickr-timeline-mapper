# mapper.rb

require 'rubygems'
require 'sinatra'

require 'flickr'
#require 'rack-flash'
#require 'digest/md5'

#require 'models'

APP_CONFIG = {
  :flickr_cache_file => "./flickr.cache",
  :flickr_key => "861cbf0ec56b1f90c78c1e7688540208",
  :flickr_shared_secret => "c26fac7e0bb8a356",
  :flickr_id => "54075897@N00",
  :rflickr_lib => true
}  

['/', '/home'].each do |path|
  get path do
    
    get_flickr
    @user = @flickr.people.findByUsername("jimlambie")    
    @locations = {}    
    get_photos_by_tag
    erb :home
  end
end

get '/tag/:tag' do
  get_flickr
  @user = @flickr.people.findByUsername("jimlambie")    
  @tag = params[:tag]
  @locations = {}    
  get_photos_by_tag(@tag)
  erb :home  
end

def get_flickr
  @flickr
  if @flickr.nil?
    @flickr = Flickr.new(APP_CONFIG[:flickr_cache_file], APP_CONFIG[:flickr_key], APP_CONFIG[:flickr_shared_secret])
  end
end

def get_photos_by_tag(tag=nil)
  @flickr_photos = @flickr.photos.search(@user, tag || 'phone')
  @flickr_photos.each { |photo|
    
    p = @flickr.photos.getInfo(photo)
    #puts p.dates[:taken]
    #puts p.title
    
    #photo.title = p.title
    #puts photo.title
    
    #local_photo = Photo.find(photo.id)
        
    coords = @flickr.photos.getExif(photo.id).exif.select { |e| e.tag =~ /GPS(.+)tude$/ && e.tagspace == "GPS" }
  
    coords.each { |c|
      c.clean.scan(/(\d+) deg (\d+)' (\d.+)\" (N|S)/).map do |d,m,s,o|
        @latitude = convert_to_decimal(d,m,s,o)
      end
      c.clean.scan(/(\d+) deg (\d+)' (\d.+)\" (E|W)/).map do |d,m,s,o|
        @longitude = convert_to_decimal(d,m,s,o)
      end
    }
    
    @locations.store(photo.id, [@latitude, @longitude])
  }
  
end

def convert_to_decimal(d,m,s,o)
  x = d.to_f + m.to_f/60 +s.to_f/3600
  if o =~ /S|W/
    x = x * -1
  end
  x
end