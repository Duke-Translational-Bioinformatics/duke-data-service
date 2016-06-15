require 'rails_helper'

RSpec.describe KindnessFactory do
  subject { KindnessFactory }
  let(:not_kinded_model) { Affiliation }
  let(:unknown_kind) { "dds-not-a-kind" }

  it { is_expected.to respond_to :kinded_models }

  describe 'is_kinded_model?' do
    it { is_expected.to respond_to(:is_kinded_model?).with(1).argument }

    it 'should return false for models not kinded' do
      expect(KindnessFactory.is_kinded_model?(not_kinded_model)).not_to be
    end

    it 'should return true for kinded models' do
      KindnessFactory.kinded_models.each do |kinded_model|
        expect(KindnessFactory.is_kinded_model?(kinded_model)).to be
      end
    end
  end

  describe 'by_kind' do
    it { is_expected.to respond_to(:by_kind).with(1).argument }

    it 'should raise a NameError exception if the "kind" is not a recognized kinded model' do
      expect{
        KindnessFactory.by_kind(unknown_kind)
      }.to raise_error(NameError)
    end
    it 'should take a valid kinded model "kind" and return the Class for that model' do
      KindnessFactory.kinded_models.each do |kinded_model|
        expect(kinded_model).to include(Kinded)
        klass = KindnessFactory.by_kind(kinded_model.new.kind)
        expect(klass.class.name).to eq(kinded_model.class.name)
      end
    end
  end
end
