class AssessmentsController < ApplicationController
  rescue_from ActionController::ParameterMissing do |exception|
    redirect_to root_url, alert: "Error: #{exception.message}"
  end

  def show
    @assessment = Assessment.find(params[:id])
    @patient = @assessment.patient
    @observations = @assessment.observations
  end

  def edit
    @assessment = Assessment.find(params[:id])
    @patient = @assessment.patient
  end

  def update
    @assessment = Assessment.find(params[:id])

    if @assessment.update(assessment_params)
      redirect_to assessment_path(@assessment), notice: "Assessment updated successfully."
    else
      @patient = @assessment.patient
      render :edit, status: :unprocessable_entity
    end
  end

  def import
    if import_params[:file].present?
      content = import_params[:file].tempfile.read.force_encoding('UTF-8')
      Rails.logger.info "Importing Assessments: #{content.inspect}"
      @import = AssessmentImport.new(content:)
      if @import.save
        ImportAssessmentsJob.set(wait: 5.seconds).perform_later(@import.id)
        redirect_to root_url, notice: "Assessments import started."
      end
    else
      redirect_to root_url, alert: "File missing"
    end
  end

  private

  def assessment_params
    params.require(:assessment).permit(
      observations_attributes: [ :id, :value, :units ]
    )
  end

  def import_params
    params.permit(:file, :authenticity_token, :commit)
  end
end
