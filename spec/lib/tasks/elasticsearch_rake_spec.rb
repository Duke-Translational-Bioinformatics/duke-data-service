require 'rails_helper'

describe "elasticsearch", :if => ENV['TEST_RAKE_SEARCH'] do
  describe "elasticsearch:index:create" do
    include_context "rake"
    let(:task_name) { "elasticsearch:index:create" }
    it { expect(subject.prerequisites).to  include("environment") }

    before do
      current_indices = Elasticsearch::Model.client.cat.indices
      if current_indices.include? DataFile.index_name
        DataFile.__elasticsearch__.client.indices.delete index: DataFile.index_name
      end
    end

    it {
      invoke_task
      current_indices = Elasticsearch::Model.client.cat.indices
      expect(current_indices).to include DataFile.index_name
    }
  end

  describe "elasticsearch:index:index_documents" do
    include_context "rake"
    let(:task_name) { "elasticsearch:index:index_documents" }
    it { expect(subject.prerequisites).to  include("environment") }

    context 'with existing documents not already indexed' do
      around :each do |example|
        current_indices = DataFile.__elasticsearch__.client.cat.indices
        DeprecatedElasticsearchResponse.indexed_models.each do |indexed_model|
          if current_indices.include? indexed_model.index_name
            indexed_model.__elasticsearch__.client.indices.delete index: indexed_model.index_name
          end
          indexed_model.__elasticsearch__.client.indices.create(
            index: indexed_model.index_name,
            body: {
              settings: indexed_model.settings.to_hash,
              mappings: indexed_model.mappings.to_hash
            }
          )
        end
        Elasticsearch::Model.client.indices.flush

        @data_file = FactoryGirl.create(:data_file)
        @folder = FactoryGirl.create(:folder)

        example.run

        DeprecatedElasticsearchResponse.indexed_models.each do |indexed_model|
          indexed_model.__elasticsearch__.client.indices.delete index: indexed_model.index_name
        end
      end

      it {
        invoke_task
        Elasticsearch::Model.client.indices.flush
        expect(DataFile.__elasticsearch__.search(@data_file.name).count).to eq 1
        expect(Folder.__elasticsearch__.search(@folder.name).count).to eq 1
      }
    end

    describe 'with existing documents indexed already' do
      around :each do |example|
        # initialize mappings
        current_indices = DataFile.__elasticsearch__.client.cat.indices
        DeprecatedElasticsearchResponse.indexed_models.each do |indexed_model|
          if current_indices.include? indexed_model.index_name
            indexed_model.__elasticsearch__.client.indices.delete index: indexed_model.index_name
          end
          indexed_model.__elasticsearch__.client.indices.create(
            index: indexed_model.index_name,
            body: {
              settings: indexed_model.settings.to_hash,
              mappings: indexed_model.mappings.to_hash
            }
          )
        end
        Elasticsearch::Model.client.indices.flush

        @data_file = FactoryGirl.create(:data_file)
        @data_file.__elasticsearch__.index_document
        @folder = FactoryGirl.create(:folder)
        @folder.__elasticsearch__.index_document

        DeprecatedElasticsearchResponse.indexed_models.each do |indexed_model|
          indexed_model.__elasticsearch__.refresh_index!
        end

        example.run

        DeprecatedElasticsearchResponse.indexed_models.each do |indexed_model|
          indexed_model.__elasticsearch__.client.indices.delete index: indexed_model.index_name
        end
      end

      it {
        expect(DataFile.__elasticsearch__.search(@data_file.name).count).to eq 1
        expect(Folder.__elasticsearch__.search(@folder.name).count).to eq 1
        invoke_task
        expect(DataFile.__elasticsearch__.search(@data_file.name).count).to eq 1
        expect(Folder.__elasticsearch__.search(@folder.name).count).to eq 1
      }
    end
  end

  describe "elasticsearch:index:drop" do
    include_context "rake"
    let(:task_name) { "elasticsearch:index:drop" }
    it { expect(subject.prerequisites).to  include("environment") }

    around :each do |example|
      # initialize mappings
      current_indices = DataFile.__elasticsearch__.client.cat.indices
      DeprecatedElasticsearchResponse.indexed_models.each do |indexed_model|
        if current_indices.include? indexed_model.index_name
          indexed_model.__elasticsearch__.client.indices.delete index: indexed_model.index_name
        end
        indexed_model.__elasticsearch__.client.indices.create(
          index: indexed_model.index_name,
          body: {
            settings: indexed_model.settings.to_hash,
            mappings: indexed_model.mappings.to_hash
          }
        )
      end
      Elasticsearch::Model.client.indices.flush

      @data_file = FactoryGirl.create(:data_file)
      @folder = FactoryGirl.create(:folder)

      DeprecatedElasticsearchResponse.indexed_models.each do |indexed_model|
        indexed_model.__elasticsearch__.refresh_index!
      end

      example.run

      current_indices = DataFile.__elasticsearch__.client.cat.indices
      DeprecatedElasticsearchResponse.indexed_models.each do |indexed_model|
        if current_indices.include? indexed_model.index_name
          indexed_model.__elasticsearch__.client.indices.delete index: indexed_model.index_name
        end
      end
    end

    it {
      invoke_task
      current_indices = DataFile.__elasticsearch__.client.cat.indices
      DeprecatedElasticsearchResponse.indexed_models.each do |indexed_model|
        expect(current_indices).not_to include indexed_model.index_name
      end
    }
  end

  describe "elasticsearch:index:rebuild" do
    include_context "rake"
    let(:task_name) { "elasticsearch:index:rebuild" }
    it { expect(subject.prerequisites).to  include("environment") }

    around :each do |example|
      current_indices = DataFile.__elasticsearch__.client.cat.indices
      DeprecatedElasticsearchResponse.indexed_models.each do |indexed_model|
        if current_indices.include? indexed_model.index_name
          indexed_model.__elasticsearch__.client.indices.delete index: indexed_model.index_name
        end
        indexed_model.__elasticsearch__.client.indices.create(
          index: indexed_model.index_name,
          body: {
            settings: indexed_model.settings.to_hash,
            mappings: indexed_model.mappings.to_hash
          }
        )
      end
      Elasticsearch::Model.client.indices.flush

      @data_file = FactoryGirl.create(:data_file)
      @folder = FactoryGirl.create(:folder)

      DeprecatedElasticsearchResponse.indexed_models.each do |indexed_model|
        indexed_model.__elasticsearch__.refresh_index!
      end

      example.run

      DeprecatedElasticsearchResponse.indexed_models.each do |indexed_model|
        indexed_model.__elasticsearch__.client.indices.delete index: indexed_model.index_name
      end
    end

    context 'ENV[RECREATE_SEARCH_MAPPINGS] not true' do
      it {
        invoke_task expected_stderr: /ENV\[RECREATE_SEARCH_MAPPINGS\] false/
      }
    end

    context 'ENV[RECREATE_SEARCH_MAPPINGS] true' do
      before do
        ENV['RECREATE_SEARCH_MAPPINGS'] = "true"
      end

      it {
        invoke_task expected_stdout: /mappings rebuilt/
      }
    end
  end
end
