class ImportAssessmentsJob < ApplicationJob
  queue_as :default

  PATIENT_DELIMITER_REGEX = /(?=^([^|]*\|){3}[^|]*$)/

  def perform(id)
    read_file(id)
    return false if @file.nil?

    import_rows(@file)
    broadcast_summary
    cleanup
  end

  def read_file(id)
    @file = AssessmentImport.find(id)
  rescue Mongoid::Errors::DocumentNotFound
    Turbo::StreamsChannel.broadcast_replace_to(
      "import_assessments_channel",
      target: "assessment-import-notice", 
      partial: "assessments/notice",
      locals: {
        total_imported: 0,
        notice: "File not found"
      }
    )
  end

  def import_rows(file)
    @assessment_groups = file.content.split(PATIENT_DELIMITER_REGEX).reject { |group| group.length < 4 }
    @assessment_groups.each do |group|
      rows = group.split("\n")
      patient_row = rows.first
      observation_rows = rows[1..]
      name, dob, sex_at_birth, reference = patient_row.split("|")
      @patient = Patient.find_or_create_by(name:, dob:, sex_at_birth: (sex_at_birth == "F" ? "Female" : "Male"))
      @assessment = @patient.assessments.find_or_create_by(reference:)
      @observations = observation_rows.map do |obs_row|
        code, value, units = obs_row.split("|")
        obs = @assessment.observations.find_or_create_by(code:).tap do |obs|
          obs.value = value
          obs.units = units
          obs.save!
        end
      end
      @assessment.observations = @observations
      @assessment.save!
    end
  end

  def broadcast_summary
    Turbo::StreamsChannel.broadcast_replace_to(
      "import_assessments_channel",
      target: "assessment-import-notice",
      partial: "assessments/notice",
      locals: {
        total_imported: @assessment_groups.size,
        notice: "Assessments imported successfully"
      }
    )
  end

  def cleanup
    @file.destroy
  end
end
