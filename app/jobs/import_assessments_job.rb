class ImportAssessmentsJob < ApplicationJob
  queue_as :default

  PATIENT_DELIMITER_REGEX = /(?=^([^|]*\|){3}[^|]*$)/

  # - Read, parse, and validate the file content
  # - For each file, extract patient information, assessment reference, and observations
  # - Create or update `Patient`, `Assessment`, and `Observation` records in the database
  #   following these rules:
  #   - **Patient:** Find existing by `name` + `dob` + `sex_at_birth`, or create new
  #   - **Assessment:** Find existing by `reference` within patient, or create new
  #   - **Observation:** Find existing by `code` within assessment and update `value`/`units`, or create new
  # - Return a summary of the import process, including the number of patients, assessments, and observations created or updated
  # - Log the import process to the console
  def perform(file_path)
    read_file(file_path)
    import_rows(@file)
    # TODO: broadcast summary?
  end

  def read_file(file_path)
    @file = File.read(file_path)
  end

  def import_rows(file)
    file.split(PATIENT_DELIMITER_REGEX).reject { |record| record.length < 4 }.each do |record|
      rows = record.split("\n")
      patient_row = rows.first
      observation_rows = rows[1..]
      @patient = Patient.find_or_create_by(
        name: patient_row.split("|")[0],
        dob: patient_row.split("|")[1],
        sex_at_birth: patient_row.split("|")[2] == "F" ? "Female" : "Male"
      )
      @assessment = @patient.assessments.find_or_create_by(
        reference: patient_row.split("|")[3]
      )
      @observations = observation_rows.map do |obs_row|
        obs = @assessment.observations.find_or_create_by(code: obs_row.split("|")[0]).tap do |obs|
          obs.value = obs_row.split("|")[1]
          obs.units = obs_row.split("|")[2]
          obs.save!
        end
      end
      @assessment.observations = @observations
      @assessment.save!
    end
  end
end
