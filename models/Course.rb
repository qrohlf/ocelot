class Course < ActiveRecord::Base
    has_many :tutors
end