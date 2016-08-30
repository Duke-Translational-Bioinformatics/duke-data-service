class Property < ActiveRecord::Base
  include RequestAudited
  audited

  belongs_to :template

  validates :key, presence: true,
    uniqueness: {case_sensitive: false},
    format: {with: /\A[a-z0-9_]*\z/i},
    length: {maximum: 60}
  validates :label, presence: true
  validates :description, presence: true
  validates :data_type, presence: true, 
    inclusion: {in: :available_data_types}

  private

  def available_data_types
    [ 'string',
      'long',
      'integer',
      'short',
      'byte',
      'double',
      'float',
      'date',
      'boolean',
      'binary' ]
  end
end
