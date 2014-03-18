# global settings go here
configure do 
    set :app_name, "Ocelot"
    # Navigation:
    # you can specify the url as a string
    # or you can pass a hash of other items
    # to create a dropdown
    set :nav_left, {
        'Tutors' => '/tutors',
        'Courses' => '/courses',
        'New' => {
            'Tutor' => '/tutors/new',
            'Course' => '/courses/new'
        }
    }
end
