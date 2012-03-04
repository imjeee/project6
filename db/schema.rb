# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20100224000112) do

  create_table "agents", :force => true do |t|
    t.string   "name",         :default => "", :null => false
    t.integer  "user_id",      :default => 0,  :null => false
    t.datetime "created_at"
    t.text     "saved"
    t.string   "class_name",   :default => "", :null => false
    t.string   "filename",     :default => "", :null => false
    t.integer  "size"
    t.string   "content_type"
  end

  add_index "agents", ["user_id"], :name => "fk_agents_users"

  create_table "agents_games", :id => false, :force => true do |t|
    t.integer "agent_id", :default => 0, :null => false
    t.integer "game_id",  :default => 0, :null => false
  end

  add_index "agents_games", ["agent_id", "game_id"], :name => "index_agents_games_on_agent_id_and_game_id", :unique => true
  add_index "agents_games", ["game_id"], :name => "fk_agents_games_games"

  create_table "games", :force => true do |t|
    t.string   "name",         :default => "", :null => false
    t.integer  "user_id",      :default => 0,  :null => false
    t.datetime "created_at"
    t.text     "saved"
    t.string   "class_name",   :default => "", :null => false
    t.string   "filename",     :default => "", :null => false
    t.integer  "size"
    t.string   "content_type"
  end

  add_index "games", ["user_id"], :name => "fk_games_users"

  create_table "participants", :id => false, :force => true do |t|
    t.integer "result_id", :default => 0, :null => false
    t.integer "agent_id",  :default => 0, :null => false
    t.integer "player_id", :default => 0, :null => false
    t.integer "score"
    t.text    "result"
    t.boolean "winner"
    t.text    "saved"
  end

  add_index "participants", ["agent_id"], :name => "fk_participants_agents"
  add_index "participants", ["player_id"], :name => "fk_participants_players"
  add_index "participants", ["result_id", "agent_id", "player_id"], :name => "index_participants_on_result_id_and_agent_id_and_player_id", :unique => true

  create_table "players", :force => true do |t|
    t.string  "name",     :default => "",   :null => false
    t.integer "game_id",  :default => 0,    :null => false
    t.boolean "required", :default => true, :null => false
  end

  add_index "players", ["game_id"], :name => "fk_players_games"

  create_table "results", :force => true do |t|
    t.integer  "game_id",    :default => 0, :null => false
    t.integer  "user_id",    :default => 0, :null => false
    t.datetime "created_at",                :null => false
    t.text     "result",                    :null => false
    t.text     "saved"
  end

  add_index "results", ["game_id"], :name => "fk_results_games"
  add_index "results", ["user_id"], :name => "fk_results_users"

  create_table "users", :force => true do |t|
    t.string   "login"
    t.string   "email"
    t.string   "crypted_password",          :limit => 40
    t.string   "salt",                      :limit => 40
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remember_token"
    t.datetime "remember_token_expires_at"
  end

end
