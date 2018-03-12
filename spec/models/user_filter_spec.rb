require 'rails_helper'

RSpec.describe UserFilter do
  subject { UserFilter.new }
  let(:test_user) { FactoryBot.create(:user, :delong) }
  let(:full_name_contains) { test_user.display_name.split(' ').first[0,3] }
  let(:first_name_begins_with) { test_user.first_name[0,3] }
  let(:last_name_begins_with) { test_user.last_name[0,3] }
  let(:other_user_first_name) { FactoryBot.create(:user, first_name: test_user.first_name) }
  let(:other_user_last_name) { FactoryBot.create(:user, last_name: test_user.last_name) }
  let(:other_user_name_contains) { FactoryBot.create(:user, display_name: "#{Faker::Name.first_name} #{test_user.display_name.split(' ').first} #{Faker::Name.last_name}")}
  let(:not_found) { SecureRandom.hex }

  it 'should support a query method' do
    expect(subject).to respond_to :query
  end

  it 'should return all users by default' do
    expect(subject.query(User.all).count).to eq(User.count)
  end

  describe 'with unsupported query parameters' do
    subject { UserFilter.new(unsupported: 'unsupported').query(User.all) }

    it 'should ignore them and return all users' do
      expect(subject.count).to eq(User.count)
    end
  end

  describe 'full_name_contains' do
    describe 'when users exist that match the query' do
      subject { UserFilter.new(full_name_contains: full_name_contains).query(User.all) }

      it 'should return only users whose display_name contains the query' do
        expect(subject.count).to be > 0
        subject.each do |user|
          expect(user.display_name).to match(full_name_contains)
        end
      end
    end

    describe 'when no user matches the query' do
      subject { UserFilter.new(full_name_contains: not_found).query(User.all) }

      it 'should return an empty collection when no user contains the query' do
        expect(subject.count).to eq(0)
      end
    end

    describe 'queries' do
      let(:capitalized) { UserFilter.new(full_name_contains: full_name_contains.capitalize).query(User.all) }
      let(:upcased) { UserFilter.new(full_name_contains: full_name_contains.upcase).query(User.all) }
      let(:downcased) { UserFilter.new(full_name_contains: full_name_contains.downcase).query(User.all) }

      it 'should be case insensitive' do
        expect(capitalized.count).to be > 0
        capitalized.each do |user|
          expect(user.display_name.downcase).to match(full_name_contains.downcase)
        end

        expect(upcased.count).to be > 0
        upcased.each do |user|
          expect(user.display_name.downcase).to match(full_name_contains.downcase)
        end

        expect(upcased.count).to be > 0
        upcased.each do |user|
          expect(user.display_name.downcase).to match(full_name_contains.downcase)
        end
      end
    end
  end

  describe 'first_name_begins_with' do
    describe 'when existing users match the query' do
      subject { UserFilter.new(first_name_begins_with: first_name_begins_with).query(User.all) }

      it 'should return only users whose first_name begins_with the query' do
        expect(subject.count).to be > 0
        subject.each do |user|
          expect(user.first_name).to start_with(first_name_begins_with)
        end
      end
    end

    describe 'when no user matches the query' do
      subject { UserFilter.new(first_name_begins_with: not_found).query(User.all) }

      it 'should return an empty collection when no user contains the query' do
        expect(subject.count).to eq(0)
      end
    end

    describe 'queries' do
      let(:capitalized) { UserFilter.new(first_name_begins_with: first_name_begins_with.capitalize).query(User.all) }
      let(:upcased) { UserFilter.new(first_name_begins_with: first_name_begins_with.upcase).query(User.all) }
      let(:downcased) { UserFilter.new(first_name_begins_with: first_name_begins_with.downcase).query(User.all) }

      it 'should be case insensitive' do
        expect(capitalized.count).to be > 0
        capitalized.each do |user|
          expect(user.first_name.downcase).to start_with(first_name_begins_with.downcase)
        end

        expect(upcased.count).to be > 0
        upcased.each do |user|
          expect(user.first_name.downcase).to start_with(first_name_begins_with.downcase)
        end

        expect(upcased.count).to be > 0
        upcased.each do |user|
          expect(user.first_name.downcase).to start_with(first_name_begins_with.downcase)
        end
      end
    end
  end

  describe 'last_name_begins_with' do
    describe 'when existing users match the query' do
      subject { UserFilter.new(last_name_begins_with: last_name_begins_with).query(User.all) }

      it 'should return only users whose last_name begins_with the query' do
        expect(subject.count).to be > 0
        subject.each do |user|
          expect(user.last_name).to start_with(last_name_begins_with)
        end
      end
    end

    describe 'when no user matches the query' do
      subject { UserFilter.new(last_name_begins_with: not_found).query(User.all) }

      it 'should return an empty collection when no user contains the query' do
        expect(subject.count).to eq(0)
      end
    end

    describe 'queries' do
      let(:capitalized) { UserFilter.new(last_name_begins_with: last_name_begins_with.capitalize).query(User.all) }
      let(:upcased) { UserFilter.new(last_name_begins_with: last_name_begins_with.upcase).query(User.all) }
      let(:downcased) { UserFilter.new(last_name_begins_with: last_name_begins_with.downcase).query(User.all) }

      it 'should be case insensitive' do
        expect(capitalized.count).to be > 0
        capitalized.each do |user|
          expect(user.last_name.downcase).to start_with(last_name_begins_with.downcase)
        end

        expect(upcased.count).to be > 0
        upcased.each do |user|
          expect(user.last_name.downcase).to start_with(last_name_begins_with.downcase)
        end

        expect(upcased.count).to be > 0
        upcased.each do |user|
          expect(user.last_name.downcase).to start_with(last_name_begins_with.downcase)
        end
      end
    end
  end

  describe 'combinations' do
    describe 'first_name_begins_with with last_name_begins_with' do
      subject {
        UserFilter.new(
          first_name_begins_with: first_name_begins_with,
          last_name_begins_with: last_name_begins_with).query(User.all)
        }
    end

    describe 'first_name_begins_with with full_name_contains' do
      subject {
        UserFilter.new(
          first_name_begins_with: first_name_begins_with,
          full_name_contains: full_name_contains).query(User.all)
        }
      it 'should return matching users' do
        expect(subject.count).to be > 0
        subject.each do |user|
          expect(user.first_name).to start_with(first_name_begins_with)
          expect(user.display_name).to match(full_name_contains)
        end
      end
    end

    describe 'last_name_begins_with with full_name_contains' do
      subject {
        UserFilter.new(
          last_name_begins_with: last_name_begins_with,
          full_name_contains: full_name_contains).query(User.all)
      }
      it 'should return matching users' do
        expect(subject.count).to be > 0
        subject.each do |user|
          expect(user.last_name).to start_with(last_name_begins_with)
          expect(user.display_name).to match(full_name_contains)
        end
      end
    end

    describe 'first_name_begins_with with last_name_begins_with and full_name_contains' do
      subject {
        UserFilter.new(
          last_name_begins_with: last_name_begins_with,
          first_name_begins_with: first_name_begins_with,
          full_name_contains: full_name_contains).query(User.all)
      }
      it 'should return matching users' do
        expect(subject.count).to be > 0
        subject.each do |user|
          expect(user.first_name).to start_with(first_name_begins_with)
          expect(user.last_name).to start_with(last_name_begins_with)
          expect(user.display_name).to match(full_name_contains)
        end
      end
    end
  end
end
