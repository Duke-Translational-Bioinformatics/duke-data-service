require 'rails_helper'

describe ApplicationPolicy do
  subject { described_class.new(user, record) }
  let(:user) { User.new }
  let(:record) { double("record") }
  before(:example) do
    allow(record).to receive(:project_permissions).and_return(ProjectPermission.unscoped)
  end

  it { expect { subject }.not_to raise_error }

  context 'with nil user' do
    let(:user) { nil }
    it { expect { subject }.to raise_error(Pundit::NotAuthorizedError, "must be logged in") }
  end

  it { is_expected.to respond_to(:user) }
  describe '#user' do
    it { expect(subject.user).to eq(user) }
  end

  it { is_expected.to respond_to(:record) }
  describe '#record' do
    it { expect(subject.record).to eq(record) }
  end

  it { is_expected.to respond_to(:index?) }
  describe '#index?' do
    it { expect(subject.index?).to be_falsey }
  end

  it { is_expected.to respond_to(:show?) }
  describe '#show?' do
    it { expect(subject.show?).to be_falsey }
  end

  it { is_expected.to respond_to(:create?) }
  describe '#create?' do
    it { expect(subject.create?).to be_falsey }
  end

  it { is_expected.to respond_to(:new?) }
  describe '#new?' do
    it { expect(subject.new?).to be_falsey }
  end

  it { is_expected.to respond_to(:update?) }
  describe '#update?' do
    it { expect(subject.update?).to be_falsey }
  end

  it { is_expected.to respond_to(:edit?) }
  describe '#edit?' do
    it { expect(subject.edit?).to be_falsey }
  end

  it { is_expected.to respond_to(:destroy?) }
  describe '#destroy?' do
    it { expect(subject.destroy?).to be_falsey }
  end
end

