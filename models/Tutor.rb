class Tutor < ActiveRecord::Base
    has_and_belongs_to_many :courses
    attr_readonly :name #have to update firstname lastname seperately

    def name
        "#{first_name} #{last_name}"
    end
end