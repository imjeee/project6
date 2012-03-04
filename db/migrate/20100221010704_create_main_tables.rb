class CreateMainTables < ActiveRecord::Migration
  def self.up
    create_table "games", :force => true do |t|
      t.column :name,           :string, :null => false
      t.column :user_id,         :integer, :null => false
      t.column :created_at,    :datetime
      t.column :saved,           :text
      t.column :class_name,   :string, :null => false
      t.column :filename,        :string, :null => false
      t.column :size,              :integer
      t.column :content_type, :string
    end
    
    create_table "players", :force => true do |t|
      t.column :name,           :string, :null => false
      t.column :game_id,       :integer, :null => false
      t.column :required,       :boolean, :null => false, :default => 1
    end
    
    create_table "agents", :force => true do |t|
      t.column :name,            :string, :null => false
      t.column :user_id,         :integer, :null => false
      t.column :created_at,    :datetime
      t.column :saved,           :text
      t.column :class_name,    :string, :null => false
      t.column :filename,        :string, :null => false
      t.column :size,              :integer
      t.column :content_type, :string
    end
    
    create_table "agents_games", :force => true, :id => false do |t|
      t.column :agent_id,        :integer, :null => false
      t.column :game_id,        :integer, :null => false
    end
    
    add_index :agents_games, [:agent_id, :game_id], :unique => true
    
    create_table "results", :force => true do |t|
      t.column :game_id,       :integer, :null => false
      t.column :user_id,        :integer, :null => false
      t.column :created_at,   :datetime, :null => false
      t.column :result,          :text, :null => false
      t.column :saved,          :text
    end
    
    create_table "participants", :force => true, :id => false do |t|
      t.column :result_id,      :integer, :null => false
      t.column :agent_id,      :integer, :null => false
      t.column :player_id,      :integer, :null => false
      t.column :score,          :integer
      t.column :result,          :text
      t.column :winner,         :boolean
      t.column :saved,          :text
    end
    
    add_index :participants, [:result_id, :agent_id, :player_id], :unique => true
  end

  def self.down
    drop_table "participants"
    drop_table "results"
    drop_table "agents_games"
    drop_table "agents"
    drop_table "players"
    drop_table "games"
  end
end

