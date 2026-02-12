require "test_helper"

class ImportAssessmentsJobTest < ActiveJob::TestCase
  setup do
    @temp_file_path = Rails.root.join("tmp", "test_import.txt")
    @temp_file = File.write(@temp_file_path, <<~TEXT
      John Doe|1985-03-15|M|REF-2024-003
      2093-3|190|mg/dL
      Jane Smith|1990-07-22|F|REF-2024-004
      8480-6|118|mmHg
      8462-4|78|mmHg
      Josh Brown|1978-11-05|M|REF-2024-005
      8867-4|75|bpm
      8310-5|99.1|°F
    TEXT
    )
  end

  teardown do
    File.delete(@temp_file_path) if File.exist?(@temp_file_path)
  end

  test "job is queued in default queue" do
    assert_equal "default", ImportAssessmentsJob.new.queue_name
  end

  test "job performs with file parameter" do
    assert_nothing_raised do
      ImportAssessmentsJob.perform_now(@temp_file_path.to_s)
    end
  end

  test "job handles non-existent file gracefully" do
    assert_nothing_raised do
      ImportAssessmentsJob.perform_now("/non/existent/file.txt")
    end
  end

  test "creates patient from file data" do
    assert_difference "Patient.count", 3 do
      ImportAssessmentsJob.perform_now(@temp_file_path.to_s)
    end
  end

  test "creates assessments from file data" do
    assert_difference "Assessment.count", 3 do
      ImportAssessmentsJob.perform_now(@temp_file_path.to_s)
    end
  end

  test "creates observations from file data" do
    ImportAssessmentsJob.perform_now(@temp_file_path.to_s)
    assert_equal 1, Assessment.find_by(reference: "REF-2024-003").observations.count
    assert_equal 2, Assessment.find_by(reference: "REF-2024-005").observations.count
  end
end
