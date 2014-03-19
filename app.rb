#######################################
# Routes
# 

before do
    login User.find(session[:user]) if User.exists? session[:user]
    @scripts = Array.new
end

# Require admin permissions for all tutor and course paths
[%r{^/tutor.*}, %r{^/courses/.*}, %r{^/manage.*}].each do |route|
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
    @tutors = Tutor.all.order(last_name: :asc, first_name: :asc)
    haml :tutors, {locals: {title: 'All Tutors'}}
end

get '/tutors/json' do
    Tutor.all.to_json(only: [:id], methods: [:name])
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
    @tutor.destroy
    redirect '/tutors'
end

get '/tutors/:id/edit' do 
    @tutor = Tutor.find(params[:id])
    params.merge! @tutor.attributes.to_options
    params[:courses] = @tutor.courses.map(&:name).join(',')
    haml :edit_tutor
end

put '/tutors/:id/edit' do 
    page_title "Edit Tutor"
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
    @courses = Course.all.order(name: :asc)
    haml :courses, {locals: {title: 'All Courses'}}
end

get '/courses/json' do
    Course.all.map(&:name).to_json
end

get '/courses/new' do
    page_title "New Course"
    haml :new_course
end

post '/courses/new' do
    page_title "New Course"
    tutors = Array.new
    params[:tutors].split(',').each do |id|
        tutors << Tutor.find(id)
    end
    puts tutors
    course = Course.create(name: params[:name], tutors: tutors)
    if !course.valid?
        params[:tokens] = tutors.map{|t| {label: t.name, value: t.id}}.to_json
        flash.now[:info] = course.errors.map{|attr, msg| "#{attr.to_s.humanize} #{msg}"}.join("<br>")
        haml :new_course
    else 
        flash[:info] = "Course #{course.name} created."
        redirect "/courses/#{course.id}"
    end
end

get '/courses/:id/edit' do 
    page_title "Edit Course"
    @course = Course.find(params[:id])
    params.merge! @course.attributes.to_options
    params[:tokens] = @course.tutors.map{|t| {label: t.name, value: t.id}}.to_json
    params[:tutors] = @course.tutors.map(&:id).join(',')
    haml :edit_course
end

put '/courses/:id/edit' do 
    page_title "Edit Course"
    @course = Course.find(params[:id])
    tutors = Array.new
    params[:tutors].split(',').each do |id|
        tutors << Tutor.find(id)
    end
    @course.update(name: params[:name], tutors: tutors)
    if !@course.valid?
        params[:tokens] = tutors.map{|t| {label: t.name, value: t.id}}.to_json
        flash.now[:info] = @course.errors.map{|attr, msg| "#{attr.to_s.humanize} #{msg}"}.join("<br>")
        haml :edit_course
    else 
        flash[:info] = "Course #{@course.name} updated."
        redirect "/courses/#{@course.id}"
    end
end

delete '/courses/:id' do 
    @course = Course.find(params[:id])
    flash[:info] = "Course '#{@course.name}' deleted" 
    @course.destroy
    redirect '/courses'
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
    page_title @course.name

    if params[:name].blank?
        flash.now[:warning] = "Name is required"
        return haml :course_form
    end

    unless params[:name] =~ /\A[[0-9a-z\s\.]]+\z/i
        flash.now[:warning] = "Name can't have special characters"
        return haml :course_form
    end

    unless params[:email] =~ /@/
        flash.now[:warning] = "Invalid email"
        return haml :course_form
    end

    if params[:message].blank?
        flash.now[:warning] = "Message is required"
        return haml :course_form
    end

    emails = @course.tutors.map(&:email)
    body = "#{params[:message]}\n\n--\nThis message was sent to all SAAB tutors for #{@course.name}."
    from = "#{params[:name]} <#{ENV['GMAIL_ACCOUNT']}>"
    Pony.mail(from: from, bcc: ENV['GMAIL_ACCOUNT'], to: emails, reply_to: params[:email], :subject => "Message from #{params[:name]} about #{@course.name}", :body => body)
    flash.now[:info] = "Message sent to #{@course.name} tutors. Thanks!"
    haml :course_form
end

get '/users/new' do
    require_admin
    page_title 'Sign Up'
    haml :signup
end

post '/users/new' do
    page_title 'Sign Up'
    user = User.create(params)
    if !user.valid?
        flash.now[:info] = user.errors.map{|attr, msg| "#{attr.to_s.humanize} #{msg}"}.join("<br>")
        haml :signup, locals: {email: params[:email]}
    else 
        flash.now[:info] = "User created. You may now log in as #{@user.email}."
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
        redirect URI.unescape(params[:dest] || '/')
    else
        flash.now[:info] = "Sorry, wrong username or password"
        haml :login, locals: {email: params[:email]}
    end
end

get '/manage' do
    page_title 'Manage'
    @tutor_count = Tutor.all.count
    @course_count = Course.all.count
    haml :manage
end

get '/manage/export' do
    export = CSV.generate do |csv|
        csv << ['lc_id', 'first_name', 'last_name', 'email', 'courses']
        Tutor.all.each do |t|
            csv << [t.lc_id, t.first_name, t.last_name, t.email, t.courses.map(&:name).join(', ')]
        end
        empty_courses = Array.new 
        Course.all.each do |c|
            empty_courses << c if c.tutors.count == 0
        end
        csv << ['EMPTY-COURSES', '', '', '', empty_courses.map(&:name).join(', ')]
    end
    content_type 'text/csv'
    attachment "tutors#{Date.today.to_s}.csv"
    export
end

post '/manage/import' do 
    new_tutors = 0
    updated_tutors = 0
    new_courses = 0
    CSV.foreach(params[:import][:tempfile], headers: true) do |row|
        attrs = row.to_hash
        courses = Array.new
        unless (attrs['courses'].nil?)
            attrs['courses'].split(',').each do |course_name|
                c = Course.find_or_create_by!(name: course_name.strip) do |c|
                    new_courses += 1 if c.new_record? #this will only run if the course is newly created
                end
                courses << c
            end
        end
        unless (attrs['lc_id'] == 'EMPTY-COURSES')
            t = Tutor.find_or_initialize_by(lc_id: attrs['lc_id'])
            new_tutors += 1 if t.new_record?
            updated_tutors += 1 if t.persisted?
            puts "updated #{t.name}" if t.persisted?
            t.update(
                lc_id: attrs['lc_id'], 
                first_name: attrs['first_name'],
                last_name: attrs['last_name'],
                email: attrs['email'],
                courses: courses
                )
        end
    end
    flash[:info] = "Import Successful. #{new_tutors} tutors and #{new_courses} courses added. #{updated_tutors} tutors updated."
    redirect '/manage', 303 #switch request method to get
end

delete '/manage/reset' do
    deleted_tutors = Tutor.destroy_all.count
    deleted_courses = Course.destroy_all.count
    flash[:info] = "Deleted #{deleted_tutors} tutors and #{deleted_courses} courses from the database"
    redirect '/manage', 303 #switch request method to get
end

#######################################
# Helpers

helpers do 
    # set the page page_title
    def page_title(t)
        @title = "#{t} | #{settings.app_name}"
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
            flash[:warning] = 'You must be logged in as an admin to view this page'
            redirect "/login?dest=#{URI.escape(request.fullpath)}", 303
            halt 403, haml(:unauthorized)
        end
    end
end

