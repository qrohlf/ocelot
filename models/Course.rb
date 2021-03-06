class Course < ActiveRecord::Base
    has_and_belongs_to_many :tutors
    validates :name, presence: true, uniqueness: true
end