require 'gamebase.rb'  # REMOVE THIS LINE BEFORE UPLOADING

class Connect4 < GameBase
  def before_players_ready
    @row_count = 6
    @col_count = 7
    @rows = (0...@row_count)
    @cols = (0...@col_count)
    @max_moves = @row_count * @col_count
    @move_count = 0
    @state.fill(0, 0, @max_moves)
    @row_count.times do |row|
      @col_count.times do |col|
        @state_keys[[row, col]] = row * @col_count + col
      end
    end
    @min_turn_moves = @max_turn_moves = 1
    @col_heights = [0] * @col_count
    @player_tokens = [1, -1]
    @directions = [[1,0], [0,1], [1,1], [-1,1]]
    @winner = nil
  end
  
  # returns the state of the board cell indexed by (row, col): 1, -1, 0 for player1, player2, empty
  # (0, 0) is the bottom left corner cell
  def index_state(row, col)
    @state[row * @col_count + col]  
  end
  
  def all_state_keys
    GameBase::SafeArray.new(@state_keys.keys)
  end
  
  # treats moves as a hash adding a {move_id => [row, col]} pair for each cell in which the calling agent can go.
  def legal_moves(moves)
    moves.clear if moves.length > 0
    @col_count.times do |col|
      height = @col_heights[col]
      moves[col] = [height, col] if height < @row_count
    end
    moves
  end
  
  def do_move(move)
    @turn_moves += 1
    @move_count += 1
    # validate move
    height = @col_heights[move]
    err = GameBase::AgentMoveError
    raise err, 'column full', caller unless height < @row_count
    # update state
    token = @player_tokens[@next_player]
    @state[height * @col_count + move] = token
    @col_heights[move] = height + 1
    # check for end of game by win or draw
    @game_over = @directions.any? {|dir| find4(height, move, dir[0], dir[1], token)}
    @winner = @next_player if @game_over
    @game_over = true if @move_count == @max_moves
    # set next player
    @next_player = 1 - @next_player unless @game_over
    nil
  end
  
  def find4(row, col, inc_row, inc_col, token)
    consecutive = count_run(row, col, -inc_row, -inc_col, token, 0)
    return true if consecutive == 4
    consecutive = count_run(row+inc_row, col+inc_col, inc_row, inc_col, token, consecutive)
    return true if consecutive == 4
    return false
  end
  private :find4
  
  def count_run(row, col, inc_row, inc_col, token, consecutive)
    while @rows === row and @cols === col and index_state(row, col) == token
      consecutive += 1
      return consecutive if consecutive == 4
      row += inc_row
      col += inc_col
    end
    return consecutive
  end
  private :count_run

  def after_players_shutdown(game_result, *agent_results)
    game_result.result = (@winner ? "player #{@winner + 1} wins" : 'draw')
    @players.length.times do |i|
      win = (i == @winner)
      agent_results[i].result = @winner ? (win ? 'win' : 'loss') : 'draw'
      agent_results[i].won_game_bool = win
    end
    Thread.current[:save_game] = @state.dup
  end
end

# REMOVE ALL THE FOLLOWING CODE BEFORE UPLOADING
if __FILE__ == $0
  require 'randomplayer.rb'
  c4 = Connect4.new([RandomPlayer, RandomPlayer])
  c4.play_game
  gr = Thread.current[:result][0]
  e = gr.exception
  if e
    puts [e.class.to_s, e.message, gr.exception_backtrace]
  else
    Thread.current[:result].each {|r| puts r.inspect}
    board = Thread.current[:save_game]
    5.downto(0) do |row|
      s = "|"
      7.times do |col|
        case board[row * 7 + col]
        when 1: s << ' X'
        when -1: s << ' O'
        when 0: s << '  '
        end
      end
      s << ' |'
      puts s
    end
  end
end