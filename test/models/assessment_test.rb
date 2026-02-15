require "test_helper"

class AssessmentTest < ActiveSupport::TestCase
  setup do
    @patient = Patient.create!(name: "Test Patient", dob: Date.today, sex_at_birth: "Male")
  end

  test "can create an assessment" do
    assessment = @patient.assessments.create!(date: "2025-01-07", reference: "ASM-TEST-001")

    assert assessment.persisted?
    assert_equal "ASM-TEST-001", assessment.reference
    assert_equal "2025-01-07", assessment.date
  end

  test "assessment belongs to patient" do
    assessment = @patient.assessments.create!(date: "2025-01-07", reference: "ASM-TEST-002")

    assert_equal @patient, assessment.patient
  end

  test "valid assessment with valid date" do
    assessment = @patient.assessments.new(date: "2025-01-07", reference: "ASM-TEST-003")

    assert assessment.valid?
  end

  test "assessment can have multiple observations" do
    assessment = @patient.assessments.create!(date: "2025-01-07", reference: "ASM-TEST-007")

    assessment.observations.create!(name: "Heart Rate", code: "8867-4", value: 72.0, units: "bpm")
    assessment.observations.create!(name: "Blood Pressure", code: "8480-6", value: 120.0, units: "mmHg")

    assert_equal 2, assessment.observations.count
  end

  test "assessment accepts nested attributes for observations" do
    assessment = @patient.assessments.create!(
      date: "2025-01-07",
      reference: "ASM-TEST-008",
      observations_attributes: [
        { name: "Heart Rate", code: "8867-4", value: 72.0, units: "bpm" },
        { name: "Temperature", code: "8310-5", value: 98.6, units: "°F" }
      ]
    )

    assert_equal 2, assessment.observations.count
    assert_equal "Heart Rate", assessment.observations.first.name
    assert_equal "Temperature", assessment.observations.last.name
  end
end
