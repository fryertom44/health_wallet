require "test_helper"

class AssessmentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @patient = Patient.create!(
      name: "Test Patient",
      dob: Date.new(1990, 5, 15),
      sex_at_birth: "Male"
    )
    @assessment = @patient.assessments.create!(
      date: "2025-01-07",
      reference: "ASM-TEST-001"
    )
  end

  test "should show assessment" do
    get assessment_url(@assessment)
    assert_response :success
  end

  test "shows assessment reference" do
    get assessment_url(@assessment)
    assert_match @assessment.reference, response.body
  end

  test "should redirect to root with notice when file is provided for import" do
    file = fixture_file_upload("test_assessments.txt", "text/txt")

    post import_assessments_url, params: { import: { file: file } }

    assert_redirected_to root_url
    assert_equal "Assessments import started.", flash[:notice]
  end

  test "should enqueue ImportAssessmentsJob when file is uploaded" do
    file = fixture_file_upload("test_assessments.txt", "text/txt")

    assert_enqueued_jobs 1, only: ImportAssessmentsJob do
      post import_assessments_url, params: { import: { file: file } }
    end
  end

  test "should redirect to root with alert when no file is provided" do
    post import_assessments_url, params: { import: { file: nil } }

    assert_redirected_to root_url
    assert_equal "File missing", flash[:alert]
  end

  test "should redirect to root with alert when file parameter is missing" do
    post import_assessments_url, params: { import: {} }

    assert_redirected_to root_url
    assert_equal "Error: param is missing or the value is empty or invalid: import", flash[:alert]
  end

  # test "should write uploaded file to temp directory" do
  #   file = fixture_file_upload('test_assessments.txt', 'text/txt')
  #   temp_path = file.tempfile.path.to_s

  #   # Ensure file doesn't exist before test
  #   File.delete(temp_path) if File.exist?(temp_path)

  #   post import_assessments_url, params: { import: { file: file } }

  #   binding.break
  #   assert File.exist?(temp_path)

  #   # Cleanup
  #   File.delete(temp_path) if File.exist?(temp_path)
  # end

  test "should pass correct temp path to job" do
    file = fixture_file_upload("test_assessments.txt", "text/txt")
    expected_temp_path = file.tempfile.path.to_s # Rails.root.join('tmp', 'full_health_medical', 'uploads', file.filename.to_s)

    assert_enqueued_with(job: ImportAssessmentsJob) do
      post import_assessments_url, params: { import: { file: file } }
    end
  end
end
