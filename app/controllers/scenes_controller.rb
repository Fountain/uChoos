class ScenesController < ApplicationController
  # GET /scenes
  # GET /scenes.xml
  def index
    @scenes = Scene.find(:all, :order => "id ASC")

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @scenes }
    end
  end

  # GET /scenes/1
  # GET /scenes/1.xml
  def show
    @scene = Scene.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @scene }
    end
  end

  # GET /scenes/new
  # GET /scenes/new.xml
  def new
    @scene = Scene.new
    @scene.story_id = params[:story_id]

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @scene }
    end
  end

  # GET /scenes/1/edit
  def edit
    @scene = Scene.find(params[:id])
    @story = Story.find_by_id(@scene.story_id)
  end

  # POST /scenes
  # POST /scenes.xml
  def create
    @scene = Scene.new(params[:scene])
    story = @scene.story_id

    respond_to do |format|
      if @scene.save
        format.html { redirect_to("/stories/#{story.to_s}", :notice => 'Scene was successfully created.') }
        format.xml  { render :xml => @scene, :status => :created, :location => @scene }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @scene.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /scenes/1
  # PUT /scenes/1.xml
  def update
    @scene = Scene.find(params[:id])

    respond_to do |format|
      if @scene.update_attributes(params[:scene])
        format.html { redirect_to(@scene, :notice => 'Scene was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @scene.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /scenes/1
  # DELETE /scenes/1.xml
  def destroy
    @scene = Scene.find(params[:id])
    story = @scene.story_id
    @scene.destroy


    respond_to do |format|
      format.html { redirect_to("/stories/#{story.to_s}", :notice => 'Scene was successfully deleted.') }
      format.xml  { head :ok }
    end
  end
end
