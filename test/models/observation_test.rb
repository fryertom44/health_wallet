require "test_helper"

class ObservationTest < ActiveSupport::TestCase
  setup do
    @patient = Patient.create!(name: "Test Patient", dob: Date.today, sex_at_birth: "Male")
    @assessment = @patient.assessments.create!(date: "2025-01-07", reference: "ASM-TEST-001")
  end

  test "can create an observation" do
    observation = @assessment.observations.create!(
      name: "Heart Rate",
      code: "8867-4",
      value: 72.0,
      units: "bpm"
    )

    assert observation.persisted?
    assert_equal "Heart Rate", observation.name
    assert_equal 72.0, observation.value
  end

  test "valid observation with valid code" do
    observation = @assessment.observations.new(
      name: "Blood Pressure",
      code: "8480-6",
      value: 120.0,
      units: "mmHg"
    )

    assert observation.valid?
  end

  test "invalid observation with invalid code" do
    observation = @assessment.observations.new(
      name: "Invalid Code",
      code: "INVALID-CODE",
      value: 100.0,
      units: "test"
    )

    assert_not observation.valid?
    assert_includes observation.errors[:code], "is not included in the list"
  end

  test "invalid observation without code" do
    observation = @assessment.observations.new(
      name: "No Code",
      value: 100.0,
      units: "test"
    )

    assert_not observation.valid?
  end

  test "valid observation with all supported codes" do
    valid_codes = Observation::CODE_NAMES.keys

    valid_codes.each do |code|
      observation = @assessment.observations.new(
        name: "Test",
        code: code,
        value: 100.0,
        units: "test"
      )
      assert observation.valid?, "Code '#{code}' should be valid"
    end
  end

  test "name_lookup returns correct name for valid code" do
    assert_equal "Heart Rate", Observation.name_lookup("8867-4")
    assert_equal "Blood Pressure (Systolic)", Observation.name_lookup("8480-6")
    assert_equal "Body Temperature", Observation.name_lookup("8310-5")
  end

  test "name_lookup returns nil for invalid code" do
    assert_nil Observation.name_lookup("INVALID-CODE")
    assert_nil Observation.name_lookup("")
  end

  test "valid_code? returns true for valid codes" do
    assert Observation.valid_code?("8867-4")
    assert Observation.valid_code?("8480-6")
    assert Observation.valid_code?("8310-5")
  end

  test "valid_code? returns false for invalid codes" do
    assert_not Observation.valid_code?("INVALID-CODE")
    assert_not Observation.valid_code?("")
    assert_not Observation.valid_code?(nil)
  end

  test "observation is embedded in assessment" do
    observation = @assessment.observations.create!(
      name: "Heart Rate",
      code: "8867-4",
      value: 72.0,
      units: "bpm"
    )

    assert_equal @assessment, observation.assessment
  end

  test "observation can have decimal values" do
    observation = @assessment.observations.create!(
      name: "Body Temperature",
      code: "8310-5",
      value: 98.6,
      units: "°F"
    )

    assert_equal 98.6, observation.value
    assert observation.valid?
  end

  test "observation can have integer values" do
    observation = @assessment.observations.create!(
      name: "Heart Rate",
      code: "8867-4",
      value: 72,
      units: "bpm"
    )

    assert_equal 72, observation.value
    assert observation.valid?
  end

  test "observation requires value" do
    observation = @assessment.observations.new(
      name: "Heart Rate",
      code: "8867-4",
      units: "bpm"
    )

    assert_not observation.valid?
  end

  test "observation requires units" do
    observation = @assessment.observations.new(
      name: "Heart Rate",
      code: "8867-4",
      value: 72.0
    )

    assert_not observation.valid?
  end

  test "CODE_NAMES is frozen" do
    assert Observation::CODE_NAMES.frozen?
  end

  test "CODE_NAMES contains expected codes" do
    expected_codes = [ "8480-6", "8462-4", "8867-4", "8310-5", "9279-1", "2708-6", "29463-7", "8302-2", "2339-0", "2093-3" ]

    expected_codes.each do |code|
      assert Observation::CODE_NAMES.key?(code), "Missing code: #{code}"
    end
  end
end
