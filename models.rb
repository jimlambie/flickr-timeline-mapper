require 'rubygems'
require 'dm-core'
require 'dm-timestamps'
require 'dm-aggregates'

DataMapper.setup(:default, "sqlite3://./db/mapper.db")

class Photo
  include DataMapper::Resource
  
  property :id,         Serial
  property :latitude,   Float
  property :longitude,  Float
  property :photo_id,   String, :length => 255
  property :photo_url,  String, :length => 255
  property :title,      String, :length => 255
  
  def self.find(photo_id)
    p = first(:photo_id => photo_id)
    p = new(:photo_id => photo_id) if u.nil?
    return p
  end
  
end

DataMapper.auto_migrate!
