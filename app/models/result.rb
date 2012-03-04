class Result < ActiveRecord::Base
	belongs_to :user
  belongs_to :game
  has_many :participants, :order => 'player_id'
  has_many :agents, :through => :participants
  has_many :players, :through => :participants
  serialize :saved
	
	cattr_reader :per_page
	@@per_page = 100
end
