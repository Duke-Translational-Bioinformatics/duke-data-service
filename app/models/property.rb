class Property < ApplicationRecord
  audited

  belongs_to :template
  has_many :meta_properties

  validates :key, presence: true,
    uniqueness: {scope: :template_id, case_sensitive: false},
    format: {with: /\A[a-z0-9_]*\z/i},
    length: {maximum: 60}
  validates :key, immutable: true, if: :has_meta_properties?
  validates :label, presence: true
  validates :description, presence: true
  validates :data_type, presence: true, 
    inclusion: {in: :available_data_types}
  validates :data_type, immutable: true, if: :has_meta_properties?
  before_destroy :validate_removability

  private

  def validate_removability
    if has_meta_properties?
      self.errors[:base] << "The property cannot be deleted if it has been associated to one or more DDS objects."
      throw :abort
    end
  end

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

  def has_meta_properties?
    meta_properties.exists?
  end
end
