#######################################
# Routes
# 

before do
    login User.find(session[:user]) if User.exists? session[:user]
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

get '/tutor/:id' do
    @tutor = Tutor.find(params[:id])
    @courses = @tutor.courses
    page_title @tutor.name
    haml :tutor
end

get '/courses' do
    page_title "Courses"
    @courses = Course.all
    haml :courses, {locals: {title: 'All Courses'}}
end

get '/course/:id' do
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

get '/payment' do 
    page_title 'Payment Example'
    haml :payment
end

# process a charge for something
# see https://stripe.com/docs/tutorials/charges for details
post '/charge/:item' do 
    # Get the credit card details submitted by the form
    token = params[:stripeToken]

    # The cost of your item should probably be stored in your model 
    # or something. Everything is specified in cents
    charge_amounts = {'example_charge' => 500, 'something_else' => 200}; 

    # Create the charge on Stripe's servers - this will charge the user's card
    begin
        charge = Stripe::Charge.create(
            :amount => charge_amounts[params[:item]], # amount in cents. 
            :currency => "usd",
            :card => token,
            :description => "description for this charge" # this shows up in receipts
            )
        page_title 'Payment Complete'
    rescue Stripe::CardError => e
        page_title 'Card Declined'
        flash.now[:warning] = 'Your card was declined'
        # The card has been declined
        puts "CardError"
    rescue Stripe::InvalidRequestError => e
        page_title 'Invalid Request'
        flash.now[:warning] = 'Something went wrong with the transaction. Did you hit refresh? Don\'t do that.'
    rescue => e
        puts e
    end

    haml :charge
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

    def require_admin
        unless @user and @user.admin
            flash.now[:warning] = 'You must be an admin to view this page'
            halt 403, haml(:unauthorized)
        end
    end

    # create a checkout button to charge the user
    # amount should be the charge amount in cents
    # amount is required
    # options takes the following keys
    # name: 'A name for the charge'
    # description: 'A description for the charge'
    # image: 'A url to an image to display'
    # item: 'Item to be passed to the charge callback'
    def checkout_button(amount, options = {})
        defaults = {"data-amount" => amount, 
            "data-description" => "2 widgets ($20.00)", 
            "data-image" => "//placehold.it/128", 
            "data-key" => ENV['STRIPE_KEY_PUBLIC'], 
            "data-name" => settings.app_name, 
            :src => "https://checkout.stripe.com/checkout.js"}

        defaults['data-name'] = options[:name] if options[:name]
        defaults['data-description'] = options[:description] if options[:description]
        defaults['data-image'] = options[:image] if options[:image]

        haml_tag :form, {action: "/charge/#{options[:item]}", method: 'POST'} do
            haml_tag 'script.stripe-button', defaults
        end
    end
end

