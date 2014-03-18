#######################################
# Routes
# 

before do
    login User.find(session[:user]) if User.exists? session[:user]
    @scripts = Array.new
end

# Require admin permissions for all tutor and course paths
[%r{^/tutor.*}, %r{^/course.*}].each do |route|
    before route do 
        require_admin
    end
end

get '/' do
    md = Redcarpet::Markdown.new(Redcarpet::Render::HTML, 
        autolink: true, 
        fenced_code_blocks: true, 
        lax_spacing: true,
        hard_wrap: true,
        tables: true)
    
    # It's convenient to write the Readme in markdown, but silly to re-render it each time.
    # Instead, we cache it in tmp until the dyno gets killed or the Readme source is modified
    if (File.exists?('tmp/Readme.html') and File.mtime('tmp/Readme.html') >= File.mtime('Readme.md'))
        @readme = File.read('tmp/Readme.html')
    else
        @readme = md.render(File.read('Readme.md'))
        Dir.mkdir 'tmp' unless Dir.exist? 'tmp'
        File.open('tmp/Readme.html', 'w') {|f| f.write(@readme)}
        puts "Regenerated tmp/Readme.html"
    end
    haml :landing
end

get '/tutors' do
    page_title "Tutors"
    @tutors = Tutor.all
    haml :tutors, {locals: {title: 'All Tutors'}}
end

get '/tutors/new' do 
    page_title 'New Tutor'
    haml :new_tutor
end

post '/tutors/new' do 
    page_title 'New Tutor'
    courses = Array.new
    params[:courses].split(',').each do |c|
        course = c.strip
        courses << Course.find_by(name: course) if Course.exists?(name: course)
    end
    tutor = Tutor.create(
        first_name: params[:first_name],
        last_name: params[:last_name],
        email: params[:email],
        lc_id: params[:lc_id],
        courses: courses
    )
    if !tutor.valid?
        flash.now[:info] = tutor.errors.map{|attr, msg| "#{attr.to_s.humanize} #{msg}"}.join("<br>")
        haml :new_tutor
    else 
        flash[:info] = "New tutor created."
        redirect "/tutors/#{tutor.id}"
    end
    
end

get '/tutors/:id' do
    @tutor = Tutor.find(params[:id])
    @courses = @tutor.courses
    page_title @tutor.name
    haml :tutor
end

delete '/tutors/:id' do
    @tutor = Tutor.find(params[:id])
    flash[:info] = "Tutor '#{@tutor.name}' deleted"
    @tutor.delete
    redirect '/tutors'
end

get '/tutors/:id/edit' do 
    @tutor = Tutor.find(params[:id])
    params.merge! @tutor.attributes.to_options
    params[:courses] = @tutor.courses.map(&:name).join(',')
    haml :edit_tutor
end

put '/tutors/:id/edit' do 
    @tutor = Tutor.find(params[:id])
    courses = Array.new
    params[:courses].split(',').each do |c|
        course = c.strip
        courses << Course.find_by(name: course) if Course.exists?(name: course)
    end
    params[:courses] = courses
    @tutor.update(params.slice(:first_name, :last_name, :email, :lc_id, :courses))
    if !@tutor.valid?
        flash.now[:info] = @tutor.errors.map{|attr, msg| "#{attr.to_s.humanize} #{msg}"}.join("<br>")
        haml :new_tutor
    else 
        flash[:info] = "Info for #{@tutor.name} updated."
        redirect "/tutors/#{@tutor.id}"
    end
end


get '/courses' do
    page_title "Courses"
    @courses = Course.all
    haml :courses, {locals: {title: 'All Courses'}}
end

get '/courses/json' do
    Course.all.map(&:name).to_json
end

get '/courses/:id' do
    @course = Course.find(params[:id])
    @tutors = @course.tutors
    page_title @course.name
    haml :course
end

get '/form/course/:id' do
    @course = Course.find(params[:id])
    @tutors = @course.tutors
    page_title @course.name
    haml :course_form
end

# todo send email
post '/form/course/:id' do
    @course = Course.find(params[:id])
    @tutors = @course.tutors
    page_title @course.name
    haml :course_form
end

get '/users/new' do
    page_title 'Sign Up'
    # log out the current user
    logout
    haml :signup
end

post '/users/new' do
    page_title 'Sign Up'
    user = User.create(params)
    if !user.valid?
        flash.now[:info] = user.errors.map{|attr, msg| "#{attr.to_s.humanize} #{msg}"}.join("<br>")
        haml :signup, locals: {email: params[:email]}
    else 
        login user
        redirect '/'
    end
end

get '/logout' do
    logout
    redirect '/'
end

get '/login' do
    page_title 'Login'
    haml :login
end

post '/login' do
    page_title 'Login'
    user = User.find_by_email(params[:email])
    if user and user.authenticate(params[:password])
        login user
        redirect '/'
    else
        flash.now[:info] = "Sorry, wrong username or password"
        haml :login, locals: {email: params[:email]}
    end
end

#######################################
# Helpers

helpers do 
    # set the page page_title
    def page_title(t)
        @page_title = "#{t} | #{settings.app_name}"
    end

    # bootstrap glyphicons
    def glyph(i)
        "<span class='glyphicon glyphicon-#{i}'></span>"
    end

    #icomoon icons
    def icon(i)
        "<span class='icon-#{i}'></span>"
    end

    def login(u)
        @user = u
        session[:user] = u.id
    end

    def logout
        @user = nil
        session.clear
    end

    def form_remember(id)
        (defined? params[id]) ? params[id] : nil
    end

    def require_admin
        unless @user and @user.admin
            flash.now[:warning] = 'You must be an admin to view this page'
            halt 403, haml(:unauthorized)
        end
    end
end

