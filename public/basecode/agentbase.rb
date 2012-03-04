class AgentBase

  def initialize(game)
    @game = game
  end

  # called by game to setup initial agent state, possibly in communication with the game
  # use obj = Thread.current[] to get persisted obj from database
  def get_ready
  end

  def take_turn(reward=nil, is_terminal=false)
    raise NoMethodError, 'take_turn must be overriden', caller
    # to examine game state:
    # @game.index_state(n)          => value of nth state variable 
    # @game.state_length            => number of state variables
    # @game.state_each {|v| block}  => nil, iterates state variables
    # @game.dup_state               => a duplicate of the state data structure
    # @game.key_state(key)          => value of state variable identified by key
    # @game.all_state_keys          => array of all state keys
    # @game.game_over               => true/false
    # N.B. @game is Enumerable
    #
    # to find out what moves are possible and tell game your move:
    # @game.legal_moves(moves)   Pass an empty hash to 'moves' and this method populates it
    #                            with move_id => move_description (key=>value) pairs
    # @game.do_move(move_id)     Ask game to execute your move. move_id must be a key in the hash 'moves'.
    #                            Agents should not attempt to call do_move on a turn with is_terminal == true
    # @game.min_turn_moves       => Least allowable do_move calls per turn or nil if not enforced
    # @game.max_turn_moves       => Most allowable do_move calls per turn or nil if not enforced
  end

  # last opportunity to execute code and communicate with the game
  # use Thread.current[] = obj to persist obj to database
  def shutdown
  end

end