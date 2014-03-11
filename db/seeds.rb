# seeds.rb is a way of automating the population of the database with testing data.

require 'csv'

CSV.foreach('db/seeds.csv') do |row|
    tutor = {
        lc_id: row[0],
        first_name: row[1],
        last_name: row[2],
        email: row[3]
    }
    Tutor.create(tutor)
end