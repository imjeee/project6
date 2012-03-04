require 'migration_helpers.rb'

class AddForeignKeys < ActiveRecord::Migration
  extend MigrationHelpers
  
  def self.up
    foreign_key :games, :user_id, :users, :id, nil, 'RESTRICT', 'CASCADE'
    foreign_key :players, :game_id, :games, :id, nil, 'CASCADE', 'CASCADE'
    foreign_key :agents, :user_id, :users, :id, nil, 'RESTRICT', 'CASCADE'
    foreign_key :agents_games, :agent_id, :agents, :id, nil, 'CASCADE', 'CASCADE'
    foreign_key :agents_games, :game_id, :games, :id, nil, 'RESTRICT', 'CASCADE'
    foreign_key :results, :user_id, :users, :id, nil, 'RESTRICT', 'CASCADE'
    foreign_key :results, :game_id, :games, :id, nil, 'RESTRICT', 'CASCADE'
    foreign_key :participants, :result_id, :results, :id, nil, 'CASCADE', 'CASCADE'
    foreign_key :participants, :agent_id, :agents, :id, nil, 'RESTRICT', 'CASCADE'
    foreign_key :participants, :player_id, :players, :id, nil, 'RESTRICT', 'CASCADE'
  end

  def self.down
    drop_foreign_key :games, :users
    drop_foreign_key :players, :games
    drop_foreign_key :agents, :users
    drop_foreign_key :agents_games, :agents
    drop_foreign_key :agents_games, :games
    drop_foreign_key :results, :users
    drop_foreign_key :results, :games
    drop_foreign_key :participants, :results
    drop_foreign_key :participants, :agents
    drop_foreign_key :participants, :players
  end
end
