class CreateExamples < ActiveRecord::Migration
  def change
    create_table :tutors do |t|
        t.string :first_name
        t.string :last_name
        t.string :email
        t.integer :lc_id

        t.timestamps
    end

    create_table :courses do |t|
        t.string :name

        t.timestamps
    end

    create_table :tutors_courses, :id => false do |t|
      t.references :tutor, :null => false
      t.references :course, :null => false
    end
  end
end
