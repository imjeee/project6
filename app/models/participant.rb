class Participant < ActiveRecord::Base
  belongs_to :game_result, :class_name => "Result", :foreign_key => "result_id"
  belongs_to :agent
  belongs_to :player
  serialize :result
  serialize :saved
end
