class Tutor < ActiveRecord::Base
    has_and_belongs_to_many :courses
    attr_readonly :name #have to update firstname lastname seperately
    validates :first_name, presence: true
    validates :email,
        presence: true,
        format: {with: /@/, allow_blank: true},
        uniqueness: {case_sensitive: false, allow_blank: true}
    validates :lc_id, 
        presence: {message: 'ID is required'},
        uniqueness: true,
        format: {with: /\d{6,7}/, message: 'ID must consist of 7 digits', allow_blank: true}

    def name
        "#{first_name} #{last_name}"
    end
end