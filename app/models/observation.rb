class Observation
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :code, type: String
  field :value, type: Float
  field :units, type: String

  embedded_in :assessment

  CODE_NAMES = {
    "8480-6" => "Blood Pressure (Systolic)",
    "8462-4" => "Blood Pressure (Diastolic)",
    "8867-4" => "Heart Rate",
    "8310-5" => "Body Temperature",
    "9279-1" => "Respiratory Rate",
    "2708-6" => "Oxygen Saturation",
    "29463-7" => "Body Weight",
    "8302-2" => "Body Height",
    "2339-0" => "Blood Glucose",
    "2093-3" => "Cholesterol"
  }.freeze

  validates_inclusion_of :code, in: CODE_NAMES.keys
  validates_presence_of :code, :value, :units
  validates_numericality_of :value

  def self.name_lookup(code)
    CODE_NAMES[code]
  end

  def self.valid_code?(code)
    CODE_NAMES.key?(code)
  end
end
