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

    post import_assessments_url, params: { file: }
    assert_response :success
  end

  test "should enqueue ImportAssessmentsJob when file is uploaded" do
    file = fixture_file_upload("test_assessments.txt", "text/txt")

    assert_enqueued_jobs 1, only: ImportAssessmentsJob do
      post import_assessments_url, params: { file: }
    end
  end

  test "should redirect to root with alert when no file is provided" do
    post import_assessments_url, params: { file: nil }

    assert_redirected_to root_url
    assert_equal "File missing", flash[:alert]
  end

  test "should redirect to root with alert when file parameter is missing" do
    post import_assessments_url, params: {}

    assert_redirected_to root_url
    assert_equal "File missing", flash[:alert]
  end
end
