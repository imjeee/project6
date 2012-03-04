class Agent < ActiveRecord::Base
  has_attachment :max_size => 500.kilobytes, :storage => :file_system, :path_prefix => 'user_code/agents'
  belongs_to :user
  has_many :agents_games
  has_many :games, :through => :agents_games
  has_many :participants
  has_many :game_results, :through => :participants, :select => "DISTINCT results.*"
  has_many :players, :through => :participants
  validates_presence_of :name, :class_name, :content_type
  serialize :saved

  cattr_reader :per_page
  @@per_page = 50
end
