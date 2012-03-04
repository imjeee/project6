class Player < ActiveRecord::Base
  belongs_to :game
  has_many :participants
  has_many :game_results, :through => :participants
  has_many :agents, :through => :participants
end
