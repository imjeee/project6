require File.dirname(__FILE__) + '/stateholders.rb'

# game authors must inherit from GameBase and override
# - legal_moves(moves)
# - do_move(move)
# - after_players_shutdown(game_result, *agent_results)
# other methods may also be overriden - see comments below
class GameBase
  include Enumerable  # for iterating over game state
  # all games expose these attributes
  attr_reader :game_over, :min_turn_moves, :max_turn_moves

  # if an agent misbehaves, we'll need an appropriate exception
  class AgentMoveError < StandardError
  end

  # VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
  # when a game is over, the results must be passed back to the web-app in a
  # consistent format. Objects of class GameResult and AgentResult are used
  # to represent all this result information.
  class GameResult
    attr_accessor :result, :exception, :exception_backtrace
    def initialize
      @result = @exception = @exception_backtrace = nil
    end
    def to_yaml_properties
      %w{ @result @exception @exception_backtrace}
    end
    def to_s
      "GameResult: \n result: #@result \n exception: #@exception \n #@exception_backtrace"
    end
  end
  class AgentResult
    attr_accessor :result, :score, :won_game_bool
    def initialize
      @result = @score = @won_game_bool = nil
    end
    def to_yaml_properties
      %w{ @result @score @won_game_bool }
    end
    def to_s
      "AgentResult: \n result: #@result \n score: #@score \n won: #@won_game_bool"
    end
  end
  # AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA

  # all well behaved games maintain these instance variables
  def initialize(player_class_array)
    @state = Vector.new  # state variables should have a fixed order
    @state_keys = {}  # hash state variable names to indexes into @state
    @players = player_class_array.map {|c| c.new(self)}
    @next_player = 0          # index of player to move, set at end of do_move
    @game_over = false      # set true in do_move on detecting end of game
    @min_turn_moves = nil   # set value in subclass to enforce, and
    @max_turn_moves = nil  # set value in subclass to enforce, and
    @turn_moves = 0          # increment in do_move if enforcing bounds
    @reward = nil  # set in do_move for @next_player if game supports learning agents
  end

  # VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
  # Called by application to play a game. Orchestrates setup, turn-taking and end-of-game.
  def play_game
    # result is an array holding a single GameResult object followed by
    # an AgentResult object for each player: [game, player1, player2, ... , playerN]
    # these result objects must be filled in when the game is over
    result = [GameResult.new]
    @players.length.times {result << AgentResult.new}

    # let's play!
    begin
      # but before play begins, call preparatory methods that might be implemented by game and agent authors
      self.before_players_ready
      @players.each {|p| p.get_ready}
      self.after_players_ready
      # play starts here - main loop for turn taking
      while(!@game_over)
        @turn_moves = 0  # used to count how many times do_move is called by an agent during its turn
        # pass control to the agent whose turn it is
        @players[@next_player].take_turn(@reward)
        # abort if the agent made too many or too few calls to do_move during its turn
        if @min_turn_moves and @turn_moves < @min_turn_moves
          raise AgentMoveError, "#{self.class} requires at least #{@min_turn_moves} moves per turn.", caller
        end
        if @max_turn_moves and @turn_moves > @max_turn_moves
          raise AgentMoveError, "#{self.class} prohibits more than #{@max_turn_moves} moves per turn.", caller
        end
      end
      # now play has ended, call closing methods that might be implemented by game and agent authors
      self.before_players_shutdown
      @players.each {|p| p.shutdown}
      # this is where result objects are filled in so game author must implement after_players_shutdown
      self.after_players_shutdown(*result)

    rescue Exception => ohno
      # an exception occurred during play so record everything about the error for user feedback
      result[0].exception = ohno
      result[0].exception_backtrace = ohno.backtrace

    ensure
      # set a thread shared variable to reference the result array so web-app can read it
      Thread.current[:result] = result
      # return true if all went well, false otherwise
      return result[0].exception.nil?
    end
  end
  # AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA

  # VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
  # METHODS WHICH MUST BE OVERRIDDEN BY GAME AUTHORS

  # called by agents, passing in a hash to be filled with {move_id => move_description} pairs
  def legal_moves(moves)
    raise NoMethodError, "legal_moves must be overridden", caller
  end

  # called by agents to execute a move: updates game @state, @next_player, @game_over
  def do_move(move)
    raise NoMethodError, "do_move must be overridden", caller
  end

  # last opportunity to execute code, passed Structs for updating with results
  # use Thread.current[:save_game] = obj to persist obj to database
  def after_players_shutdown(game_result, *agent_results)
    raise NoMethodError, "after_players_shutdown must be overridden" , caller
  end

  # AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA


  # VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
  # METHODS WHICH MAY OPTIONALLY BE OVERRIDDEN BY GAME AUTHORS

  # iterates over all state variables so that Enumerable can be used
  def each
    @state.each {|s| yield s}
    nil  # return nil to avoid exposing a ref to @state
  end
  protected :each

  # indexes a GameBase::Vector by default, which will not hold refs to mutable data like arrays & strings
  # To expose strings/arrays, override index_state and use a GameBase::SafeArray for @state
  def index_state(index)
    @state[index]
  end

  # called by agents to get the number of state variables
  def state_length
    @state.length
  end

  # called by agents to iterate over all state variables
  def state_each(&block)
    self.each(&block)  
  end

  # called by agents to get a duplicate of the state data structure
  def dup_state
    @state.dup
  end

  # called by agents to get the value of the state variable named by key
  def key_state(key)
    @state[@state_keys[key]]
  end

  # called by agents to get an array of all state variable keys
  def all_state_keys
    @state_keys.keys
  end

  # called by GameBase before play starts, so override for game state setup
  # helps avoid lengthy/problematic state setup code in game initialize method
  # use obj = Thread.current[:load_game] to get persisted obj from database
  def before_players_ready
  end

  # called by GameBase after it calls get_ready on all players but before play starts
  def after_players_ready
  end

  # called by GameBase immediately when @game_over becomes true
  def before_players_shutdown
  end

  # AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA

end