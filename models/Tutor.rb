class Tutor < ActiveRecord::Base
    has_and_belongs_to_many :courses

    def name
        "#{first_name} #{last_name}"
    end
end