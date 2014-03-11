# seeds.rb is a way of automating the population of the database with testing data.

require 'csv'

# CSV.foreach('db/tutors.csv') do |row|
#     tutor = {
#         lc_id: row[0].strip,
#         first_name: row[1].strip,
#         last_name: row[2].strip,
#         email: row[3].strip
#     }
#     Tutor.create(tutor)
# end

course_tutors = CSV.read('db/courses.csv')
course_names = course_tutors.shift
courses = Hash.new
# puts course_names[7..-1].join " "

# create the courses
course_names[7..-1].each do |name|
    courses[name.strip] = Course.create(name: name.strip)
end

course_tutors.each do |row|
    next if row[0].nil?
    user_courses = Array.new

    row.each_with_index do |val, index|
        next if index < 7
        user_courses << courses[course_names[index]] if val and val.include? '1'
    end
    tutor = {
        lc_id: row[0].strip,
        first_name: row[1].strip,
        last_name: row[2].strip,
        email: row[3].strip,
        courses: user_courses
    }
    Tutor.create(tutor)
end
