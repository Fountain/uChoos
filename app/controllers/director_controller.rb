class DirectorController < ApplicationController

  skip_before_filter :verify_authenticity_token

  #TODO catch exception for when there is no scene for that game
  def router
    story = Story.find_by_id(params[:story])
    scene = params[:scene]
    scene_index = scene.to_i - 1
    digits = params[:Digits]
    user = User.find_by_mobile_number(params[:From])
    if user
      sms = user.can_text
    end
    next_scene = nil

    # Write routing info to log
    puts "Scene: " + scene
    if digits
      puts "Digits: " + digits
    else
      puts "No digits in params"
    end
    
    if digits
      if digits == "1"
        puts "inside digit 1"
        next_scene = story.scenes[scene_index].option_one.to_s
        puts "next_scene: " + next_scene
        next_scene
      elsif digits == "2"
        puts "inside digit 2"
        next_scene = story.scenes[scene_index].option_two.to_s
        puts "next_scene: " + next_scene
        next_scene
      else
        puts "inside no scene matches that digit"
        next_scene
      end
    else
      puts "no digits found, rendering scene"
      render_scene(story, scene, sms)
      return
    end
    
    if next_scene
      puts "found next_scene"
      user.save_progress!(story, next_scene)
      render_scene(story, next_scene, sms)
      return
    else
      puts "no next_scene"
      redirect = "/director/choice/#{story.id.to_s}/#{scene.to_s}"
      # create repsonse
      @r = Twilio::Response.new
      # wrap with gather tag
      @r.append(Twilio::Say.new("I didn't understand your response!", :voice => "man"))
      # redirect to choice view    
      @r.append(Twilio::Redirect.new(redirect, :method => "GET"))

      puts "Unknown Choice: " + @r.respond
      render :xml => @r.respond
      return
    end
  end

  def story_menu
    active_stories = Story.find_all_by_active(true)
    
    if active_stories.size == 1
      @r = Twilio::Response.new
      @r.append(Twilio::Play.new("/static/game_menu.mp3"))
      @r.append(Twilio::Redirect.new("/director/router/1/1", :method => "GET"))
      puts "Story menu has one story: " + @r.respond
    elsif active_stories.size == 0
      @r = Twilio::Response.new
      @r.append(Twilio::Say.new("There are currently no stories available. Goodbye"))
      @r.append(Twilio::Hangup.new())
      puts "Story menu, no stories: " + @r.respond
    else
      menu_text = "Welcome to you choose."
      active_stories.each_with_index do |story, count|
        menu_text << "Press #{count + 1} to hear #{story.name}. "
      end
        
      @r = Twilio::Response.new
      @r.append(Twilio::Say.new("There are currently #{active_stories.size.to_s} stories available."))
      @g = @r.append(Twilio::Gather.new(:numDigits => "2", :action => '/director/tell', :method => "GET", :timeout => "6"))
      @g.append(Twilio::Say.new(menu_text))
      puts "Story menu, list stories: " + @r.respond
    end
    render :xml => @r.respond
  end

  def set_sms
    digits = params[:Digits]
    user = User.find_by_mobile_number(params[:From])
    twilio_number = params[:To]

    if digits == "1"
      user.can_text = true
      user.save
      puts 'sms: true'
      redirect_to '/director/story_menu'
    elsif digits == "2"
      user.can_text = false
      user.save
      puts 'sms: false'
      redirect_to '/director/story_menu'
    else
      #TODO make this more intelligent
      redirect_to '/static/check_sms.xml'
    end
  end

  def render_scene(story, scene, sms)
    route = "/director/router/" + story.id.to_s + "/" + scene
    redirect = "/director/choice/" + story.id.to_s + "/" + scene
    choiceless_redirect = "/director/router/" + story.id.to_s + "/" + story.scenes[scene.to_i - 1].option_one.to_s
    scene_location = scene.to_i - 1
    audio = story.scenes[scene_location].scene_audio
    
    puts "scene: " + scene
    puts "Audio: " + audio
    
    # create repsonse
    @r = Twilio::Response.new
    # play scene audio
    @r.append(Twilio::Play.new(audio))
    
    # Check if the scene has only option_one set
    if story.scenes[scene_location].choiceless?
      @r.append(Twilio::Redirect.new(choiceless_redirect, :method => "GET"))
      puts "Choiceless: " + @r.respond
    # Check if scene has no options (aka final scene)
    elsif story.scenes[scene_location].final?
      if sms
        @r.append(Twilio::Sms.new(story.scenes[scene.to_i - 1].choice_text))
      else
        @r.append(Twilio::Say.new(story.scenes[scene.to_i - 1].choice_text))
      end
      @r.append(Twilio::Hangup.new())
      puts "Final: " + @r.respond
    else
      # wrap with gather tag
      @g = @r.append(Twilio::Gather.new(:numDigits => "1", :action => route, :method => "GET", :timeout => "6"))
      # play choice audio
      @g.append(Twilio::Play.new(story.scenes[scene_location].choice_audio))
      # add response for no answer
      @r.append(Twilio::Say.new("Please enter a choice!", :voice => "man"))
      # add redirect to choice view    
      @r.append(Twilio::Redirect.new(redirect, :method => "GET"))
      puts "Scene: " + @r.respond
    end

    render :xml => @r.respond
    return false
  end

  def render_choice
    story = Story.find_by_id(params[:story])
    scene = params[:scene]
    scene_index = scene.to_i - 1
    digits = params[:Digits]
    
    puts "inside render_choice"
    
    route = "/director/router/" + story.id.to_s + "/" + scene
    redirect = "/director/choice/" + story.id.to_s + "/" + scene
    
    puts "route: " + route
    puts "redirect: " + redirect
    puts "scene_index: " + scene_index.to_s
    # create repsonse
    @r = Twilio::Response.new
    # wrap with gather tag
    @g = @r.append(Twilio::Gather.new(:numDigits => "1", :action => route, :method => "GET", :timeout => "6"))
    # play choice audio
    @g.append(Twilio::Play.new(story.scenes[scene_index].choice_audio))
    # add response for no answer
    @r.append(Twilio::Say.new("Please enter a choice!", :voice => "man"))
    # add redirect to choice view    
    @r.append(Twilio::Redirect.new(redirect, :method => "GET"))

    puts "Choice: " + @r.respond
    render :xml => @r.respond
    return
  end
  
  # TODO abstract current set up into this method
  def get_next_scene(digits, story, scene)
    next_scene = nil
    scene_index = scene.to_i - 1
    
    if digits == "1"
      puts "inside digit 1"
      next_scene = story.scenes[scene_index].option_one.to_s
      puts "next_scene: " + next_scene
      next_scene
    elsif digits == "2"
      puts "inside digit 2"
      next_scene = story.scenes[scene_index].option_two.to_s
      next_scene
    else
      puts "inside no digit found"
      next_scene
    end
  end

end
