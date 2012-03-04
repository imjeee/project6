class GamesController < ApplicationController
  before_filter :login_required
  before_filter :login_from_cookie
  before_filter :find_check_ownership, :except => [:index, :show, :new, :create]

  def find_check_ownership
    @game = Game.find(params[:id])
    unless current_user.id == @game.user.id
      flash[:notice] = 'You are not the owner of the specified record. Only the owner can perform the requested action.'
      redirect_to :action => 'show', :id => @game
    end
  end

  # GET /games
  # GET /games.xml
  def index
    if params[:filter_type].nil?
      @filter = {}
      @title = "All Games"
      @games = Game.paginate :page => params[:page], :order => "id DESC"
    else
      @filter = {:type => params[:filter_type], :id => params[:filter_id], :name => params[:filter_name]}
      @title = "Games For #{@filter[:type]}: #{@filter[:name]}"  
      case @filter[:type]
        when 'User'
          @games = current_user.games.paginate :page => params[:page], :order => 'id DESC'
      end
    end
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @games }
    end
  end

  # GET /games/1
  # GET /games/1.xml
  def show
    @game = Game.find(params[:id])
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @game }
    end
  end

  # GET /games/new
  # GET /games/new.xml
  def new
    @game = Game.new
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @game }
    end
  end

  # POST /games
  # POST /games.xml
  def create
    @game = Game.new(params[:game])
    params[:newplayer].each do |player|
      p = Player.new(player);
      next if p.name.blank?
      @game.players << p  # this does not save p to db because @game not yet saved
    end
    respond_to do |format|
      # don't like enforcing min 1 player here - much better if enforceable by models
      if !@game.players.empty? and current_user.games << @game  # saves game and players to db
        format.html do
          flash[:notice] = 'Game was successfully created.'
          redirect_to :action => 'show', :id => @game
        end
        format.xml  { render :xml => @game, :status => :created, :location => @game }
      else
        format.html do
          if @game.players.empty?
            # don't like min 1 player here - much better if enforceable by models
            flash[:notice] = 'A game must have at least one player.'
          end
          @game.filename = ''  # don't show this after an error
          render :action => 'new'
        end
        format.xml  { render :xml => @game.errors, :status => :unprocessable_entity }
      end
    end
  end

  # GET /games/1/edit
  def edit
    #@game = Game.find(params[:id])  # now performed in :find_check_ownership
  end

  # PUT /games/1
  # PUT /games/1.xml
  def update
    #@game = Game.find(params[:id])  # now performed in :find_check_ownership
    delete_player_failed = false
    params[:player].each do |id, player|
      p = @game.players.find(id);
      #p.destroy if p.name.blank?  # this line made it hard to enforce presence of one player
      if player[:name].empty?
        if @game.players.size > 1
          @game.players.delete(p) # deletes from db and players collection
        else
          # don't like min 1 player here - much better if enforceable by models
          flash[:notice] = 'A Game must have at least one player'
          delete_player_failed = true
        end
      else
        p.update_attributes(player)
      end
    end
    params[:newplayer].each do |player|
      p = Player.new(player);
      next if p.name.blank?
      @game.players << p  # this saves new player to db or returns false
    end
	respond_to do |format|
      # don't like min 1 player here - much better if enforceable by models
      if !delete_player_failed and @game.update_attributes(params[:game])
        format.html do
          flash[:notice] = 'Game was successfully updated.'
          redirect_to :action => 'show', :id => @game
        end
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @game.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /games/1
  # DELETE /games/1.xml
  def destroy
    #@game = Game.find(params[:id])  # now performed in :find_check_ownership
	  if @game.results.nil? or @game.results.empty?
      if @game.agents.nil? or @game.agents.empty?
        @game.destroy
        flash[:notice] = 'Game successfully destroyed.'
      else
        flash[:notice] = 'Game not destroyed because there are agents that can play it.'
      end
	  else
	    flash[:notice] = 'Game not destroyed because it has result records.'
	  end
    redirect_to :action => 'index', :filter_type => params[:filter_type], :filter_id => params[:filter_id], :filter_name => params[:filter_name]
#    respond_to do |format|
#      format.html { redirect_to(games_url) }
#      format.xml  { head :ok }
#    end
  end

  def download_source_code
    #@game = Game.find(params[:id])  # now performed in :find_check_ownership
    send_file @game.public_filename, :type => 'plain/text', :disposition => 'inline'
  end

  def edit_source_code
    #@game = Game.find(params[:id])  # now performed in :find_check_ownership
    code_file = File.open(@game.public_filename)
    @code = code_file.read
    code_file.close
  end

  def update_source_code
    #@game = Game.find(params[:id])  # now performed in :find_check_ownership
    @code = params[:source_code].gsub("\r\n", "\n")
    code_file = File.open(@game.public_filename, 'w')
    code_file.write @code
    code_file.close 
    flash[:notice] = 'Source code successfully updated'
    redirect_to :back
  end
end
