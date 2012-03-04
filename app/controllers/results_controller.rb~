class ResultsController < ApplicationController
  before_filter :login_required, :except => [:index]
  before_filter :login_from_cookie
	
	# GET /results
  # GET /results.xml
  def index
    if params[:filter_type].nil?
      @filter = {}
      @title = "All Results"
      @results = Result.paginate :page => params[:page], :order => "id DESC"
    else
      @filter = {:type => params[:filter_type], :id => params[:filter_id], :name => params[:filter_name]}
      @title = "Results For #{@filter[:type]}: #{@filter[:name]}"  
      case @filter[:type]
        when 'Agent'
					agent = Agent.find(@filter[:id])
					@results = agent.game_results.paginate :page => params[:page], :order => "id DESC"
        when 'Game'
				  game = Game.find(@filter[:id])
          @results = game.results.paginate :page => params[:page], :order => "id DESC"
        when 'User'
          @results = current_user.results.paginate :page => params[:page], :order => "id DESC"
      end
    end
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @results }
    end
  end

  # GET /results/1
  # GET /results/1.xml
  def show
    @result = Result.find(params[:id])
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @result }
    end
  end

  # GET /results/new
  # GET /results/new.xml
  def new
    redirect_to :controller=>'games', :action => 'index' and return if !params[:id]
    @game = Game.find(params[:id])
  end

  # GET /results/1/edit
  # users editing results not allowed

  # POST /results
  # POST /results.xml
  def create
    @result = Result.new(params[:result])
    params[:player].each do |id, player|
      if player[:id] == ""
        if Player.find(id).required?
          flash[:notice] = 'Must add all required players'
          redirect_to :action => 'new', :id=>@result.game
          return
        end
      else
        participant = @result.participants.build :player_id=>id, :agent_id=>player[:id]
      end
    end
    # determine absolute paths - relative paths violate safe level for loading untrusted.rb
    rg_controller_path = File.dirname(__FILE__)
    rg_untrusted_path = rg_controller_path + '/../../tmp/untrusted'
    rg_public_path = rg_controller_path + '/../../public'
    rg_basecode_path = rg_public_path + '/basecode'
    # load trusted base classes
    require rg_basecode_path + '/gamebase.rb'
    require rg_basecode_path + '/agentbase.rb'
    # determine game/agent filenames and class_names
    user_code_files = [@result.game.public_filename]
    agent_class_names = []
    @result.participants.each do |mp| 
      agt = Agent.find(mp.agent_id)
      user_code_files << agt.public_filename unless agent_class_names.member? agt.class_name
      agent_class_names << agt.class_name
    end
    # write untrusted match script
    user_code_boundaries = [0]
    untrusted_filename = current_user.login + '_untrusted.rb'
    untrusted_file = rg_untrusted_path + '/' + untrusted_filename
    File.open(untrusted_file, 'w') do |f|
      user_code_files.each do |u_file|
        code = File.read(rg_public_path + u_file)
        f.puts code
        user_code_boundaries << user_code_boundaries[-1]  + code.split("\n").length
      end
      f.puts "player_classes = [#{agent_class_names.join(', ')}]"
      f.puts "g = #{@result.game.class_name}.new(player_classes)"
      f.puts "g.play_game"
    end
    # prepare for improving the usefulness of error messages
    # remove the path prefixes from user_code_files
    user_code_filenames = user_code_files.map {|uf| uf.match(/\w+[.]rb\Z/)[0]}
    user_code_filenames << untrusted_filename
    # set up a RegEx and a Proc for correcting line numbers in error messages
    match_line_nos = /\w+_untrusted[.]rb:(\d+):/
    line_corrections = lambda do |dummy|
      line_no = $1.to_i
      offset = 0
      user_code_boundaries.each {|line| offset = line if line < line_no}
      filename = user_code_filenames[user_code_boundaries.index(offset)]
      offset = 0 if offset == user_code_boundaries[-1]
      line_no -= offset
      "#{current_user.login}/#{filename}:#{line_no}:"
    end
    # Proc for embellishing cryptic error messages
    improve_err_msg = lambda do |exception|
      new_msg = exception.message.gsub(match_line_nos, &line_corrections)
      if exception.is_a?(SecurityError)
        new_msg << ". Games are played with $SAFE=4 which means some operations are prohibited."
        new_msg << " Your code tried to perform a prohibited operation."
      end
      if exception.message =~ /Insecure: can't modify array/
        new_msg << " Make sure there are no calls to 'require' or 'load' in your game or agent code."
      end
      new_msg
    end
    # run untrusted match script at max safe level inside an anonymous module
    single_game_limit_sec = 10
    app_thr = Thread.current
    game_thr = Thread.new do
      $SAFE = 4
      Kernel.load(untrusted_file, true)
    end
    begin
      # wait synchronously for match to complete, or timeout and kill it
      if game_thr.join(single_game_limit_sec)
        # IS THIS A SECURITY BREACH?
        game_result = YAML.load(YAML.dump(game_thr[:result]))
        if game_result[0].exception.nil?
          # record match results
          @result.result = game_result[0].result
          @result.saved = game_thr[:save_game]
          @result.participants.size.times do |i|
            prt = @result.participants[i]
            prt_res = game_result[i+1]
            prt.result = prt_res.result
            prt.score = prt_res.score
            prt.winner = prt_res.won_game_bool
          end
        else
          @result.result = "Error in play_game method, see 'Saved' data for exception info"
          e = game_result[0].exception
          eb = game_result[0].exception_backtrace
          if eb and eb.length > 0
            eb_index = 0
            while eb[eb_index] !~ /action_controller/
              eb[eb_index] = eb[eb_index].gsub(match_line_nos, &line_corrections)
              eb_index += 1
            end
            eb[eb_index..-1] = nil
          end
          improved_msg = improve_err_msg.call(e)
          @result.saved = [e.class.to_s, improved_msg, eb ? eb : 'no backtrace available'].join(' ')
        end
      else
        game_thr.kill
        @result.result = "Game thread killed for exceeding allowable runtime"
      end
    rescue Exception => ohno
      # rescue exceptions not caused by play_game
      @result.result = "Error loading game or agent files, see 'Saved' data for exception info"
      @result.saved = [ohno.class.to_s, ': ', improve_err_msg.call(ohno)]
    ensure
		  respond_to do |format|
        # save match to db
        if current_user.results << @result
					format.html do |format|
            flash[:notice] = @result.result.is_a?(String) ? @result.result : "Result was successfully created"
            redirect_to :action => 'show', :id => @result
					end
					format.xml  { render :xml => @result, :status => :created, :location => @result }
        else
					format.html do
            flash[:notice] = "Result could not be created"
            render :action => 'new'
					end
					format.xml  { render :xml => @result.errors, :status => :unprocessable_entity }
        end
		  end
		end
  end

  # PUT /results/1
  # PUT /results/1.xml
  # users editing results not allowed

  # DELETE /results/1
  # DELETE /results/1.xml
  def destroy
    @result = Result.find(params[:id])
    Participant.delete_all "result_id = #{@result.id}"
    @result.destroy
    respond_to do |format|
      format.html do
				flash[:notice] = "Result successfully destroyed"
        redirect_to :action => 'index', :filter_type => params[:filter_type], :filter_id => params[:filter_id], :filter_name => params[:filter_name]
	    end
      format.xml  { head :ok }
    end
  end
end
