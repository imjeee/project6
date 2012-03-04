class AgentsGame < ActiveRecord::Base
  belongs_to :game
  belongs_to :agent
end
