class Game < ActiveRecord::Base
  has_attachment :max_size => 500.kilobytes, :storage => :file_system, :path_prefix => 'user_code/games'
  belongs_to :user
  has_many :players, :dependent => :destroy
  has_many :agents_games
  has_many :agents, :through => :agents_games
  has_many :results
  validates_presence_of :name, :class_name, :content_type
  serialize :saved
	
  cattr_reader :per_page
  @@per_page = 50
end
