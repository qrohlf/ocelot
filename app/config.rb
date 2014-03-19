# global settings go here
configure do 
    set :app_name, "Ocelot"
    # Navigation:
    # you can specify the url as a string
    # or you can pass a hash of other items
    # to create a dropdown
    set :nav_admin, {
        'Tutors' => '/tutors',
        'Courses' => '/courses',
        'Create New' => {
            'Tutor' => '/tutors/new',
            'Course' => '/courses/new'
        },
        'Manage' => '/manage'
    }

    set :nav, {
        'Courses' => '/courses',
        'SAAB Homepage' => 'https://college.lclark.edu/student_life/associated_students/saab/tutor/'
    }
end
