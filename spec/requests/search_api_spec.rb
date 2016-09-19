require 'rails_helper'

describe DDS::V1::SearchAPI do
  include_context 'with authentication'

  describe 'Search Provenance' do
    let!(:project) { FactoryGirl.create(:project) }
    let!(:project_permission) { FactoryGirl.create(:project_permission, :project_admin, user: current_user, project: project) }
    let!(:resource_permission) { project_permission }
    let!(:data_file) { FactoryGirl.create(:data_file, project: project) }
    let!(:start_node) { data_file.file_versions.first }
    let(:start_node_id) { start_node.id }
    let!(:activity) { FactoryGirl.create(:activity, creator: current_user) }
    let(:resource_class) { FileVersion }
    let(:resource_kind) { start_node.kind }

    # (activity)-(used)->(start_node)
    let!(:activity_used_start_node) {
      FactoryGirl.create(:used_prov_relation,
        relatable_from: activity,
        relatable_to: start_node
      )
    }

    # (activity)-(asocciatedWith)->(current_user)
    let!(:activity_associated_with_current_user) {
      FactoryGirl.create(:associated_with_user_prov_relation,
        relatable_from: current_user,
        relatable_to: activity
      )
    }
    let!(:deleted_file_version) { FactoryGirl.create(:file_version, :deleted, data_file: data_file) }

    describe 'POST /api/v1/search/provenance' do
      let(:url) { "/api/v1/search/provenance" }
      subject { post(url, payload.to_json, headers) }
      let(:called_action) { 'POST' }

      let!(:other_file) { FactoryGirl.create(:data_file, project: project) }
      let!(:other_file_version) { other_file.file_versions.first }

      # (start_node)-(derivedFrom)->(other_file_version)
      let!(:start_node_derived_from_other_file_version) {
        FactoryGirl.create(:derived_from_file_version_prov_relation,
          relatable_from: start_node,
          relatable_to: other_file_version
        )
      }

      let(:payload) {{
        start_node: {
          kind: resource_kind,
          id: start_node_id
        }
      }}
      let(:expected_nodes) { [
        start_node.id,
        activity.id,
        current_user.id,
        other_file_version.id
      ] }
      let(:expected_relationships) { [
        activity_used_start_node.id,
        activity_associated_with_current_user.id,
        start_node_derived_from_other_file_version.id
      ] }

      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'
      it_behaves_like 'a software_agent accessible resource' do
        let(:expected_response_status) { 201 }
      end

      context 'with unsupported start_node kind' do
        let(:resource_kind) { 'invalid-kind' }
        it_behaves_like 'a kinded resource'
      end

      context 'with invalid start_node_id' do
        let(:start_node_id) { 'notfoundid' }
        it_behaves_like 'an identified resource'
      end

      context 'start_node is logically deleted' do
        let(:payload) {{
          start_node: {
            kind: deleted_file_version.kind,
            id: deleted_file_version.id
          }
        }}
        it 'should return graph with deleted focus' do
          is_expected.to eq(201)
          expect(response.body).to be
          expect(response.body).not_to eq('null')
        end
      end

      context 'when all nodes and relationships accessible by user' do
        it 'should return properties for all nodes and relationships returned' do
          is_expected.to eq(201)
          expect(response.body).to be
          expect(response.body).not_to eq('null')
          response_json = JSON.parse(response.body)
          expect(response_json).to have_key('graph')
          provenance_graph = response_json['graph']
          expect(provenance_graph).to have_key('nodes')
          expect(provenance_graph['nodes']).not_to be_empty
          provenance_graph['nodes'].each do |node|
            expect(expected_nodes).to include(node['id'])
            expect(node['properties']).not_to eq('nil')
            expect(node['properties']['id']).to eq(node['id'])
          end
          expect(provenance_graph).to have_key('relationships')
          expect(provenance_graph['relationships']).not_to be_empty
          provenance_graph['relationships'].each do |relationship|
            expect(expected_relationships).to include(relationship['id'])
            expect(relationship['properties']).not_to eq('nil')
            expect(relationship['properties']['id']).to eq(relationship['id'])
          end
        end
      end

      context 'max_hops 1' do
        let(:payload) {{
          start_node: {
            kind: resource_kind,
            id: start_node_id
          },
          max_hops: 1
        }}
        let(:expected_relationships) { [
          activity_used_start_node.id,
          start_node_derived_from_other_file_version.id
        ] }

        it 'should return properties for nodes and relationships directly related to the start_node' do
          is_expected.to eq(201)
          expect(response.body).to be
          expect(response.body).not_to eq('null')
          response_json = JSON.parse(response.body)
          expect(response_json).to have_key('graph')
          provenance_graph = response_json['graph']
          expect(provenance_graph).to have_key('nodes')
          expect(provenance_graph['nodes']).not_to be_empty
          provenance_graph['nodes'].each do |node|
            expect(expected_nodes).to include(node['id'])
            expect(node['properties']).not_to eq('nil')
            expect(node['properties']['id']).to eq(node['id'])
          end
          expect(provenance_graph).to have_key('relationships')
          expect(provenance_graph['relationships']).not_to be_empty
          provenance_graph['relationships'].each do |relationship|
            expect(expected_relationships).to include(relationship['id'])
            expect(relationship['properties']).not_to eq('nil')
            expect(relationship['properties']['id']).to eq(relationship['id'])
          end
        end
      end

      context 'when a node is not accessible by user' do
        let!(:other_project) { FactoryGirl.create(:project) }
        let!(:other_file) { FactoryGirl.create(:data_file, project: other_project) }
        let!(:other_file_version) { other_file.file_versions.first }

        # (start_node)-(derivedFrom)->(other_file_version)
        let!(:start_node_derived_from_other_file_version) {
          FactoryGirl.create(:derived_from_file_version_prov_relation,
            relatable_from: start_node,
            relatable_to: other_file_version
          )
        }

        it 'should not return properties for the inaccessible node' do
          is_expected.to eq(201)
          expect(response.body).to be
          expect(response.body).not_to eq('null')
          response_json = JSON.parse(response.body)
          expect(response_json).to have_key('graph')
          provenance_graph = response_json['graph']
          expect(provenance_graph).to have_key('nodes')
          expect(provenance_graph['nodes']).not_to be_empty
          provenance_graph['nodes'].each do |node|
            expect(expected_nodes).to include(node['id'])
            if node['id'] == other_file_version.id
              expect(node['properties']).to be_nil
            end
          end
          expect(provenance_graph).to have_key('relationships')
          expect(provenance_graph['relationships']).not_to be_empty
          provenance_graph['relationships'].each do |relationship|
            expect(expected_relationships).to include(relationship['id'])
            expect(relationship['properties']).not_to eq('nil')
            expect(relationship['properties']['id']).to eq(relationship['id'])
          end
        end
      end
    end
  end

  describe 'Search Objects' do
    around :each do |example|
      current_indices = DataFile.__elasticsearch__.client.cat.indices
      ElasticsearchResponse.indexed_models.each do |indexed_model|
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

      expect(indexed_folder).to be_persisted
      indexed_folder.__elasticsearch__.index_document
      expect(indexed_data_file).to be_persisted
      indexed_data_file.__elasticsearch__.index_document

      Folder.__elasticsearch__.refresh_index!
      DataFile.__elasticsearch__.refresh_index!

      example.run

      ElasticsearchResponse.indexed_models.each do |indexed_model|
        indexed_model.__elasticsearch__.client.indices.delete index: indexed_model.index_name
      end
    end

    describe 'POST /api/v1/search' do
      let(:url) { "/api/v1/search" }
      subject { post(url, payload.to_json, headers) }
      let(:called_action) { 'POST' }
      let(:included_kinds) { ['dds-file'] }
      let(:elastic_query) {
        {
          query: {
            query_string: {
              query: "foo"
            }
          }
        }
      }
      let!(:project) { FactoryGirl.create(:project) }
      let!(:other_project) { FactoryGirl.create(:project) }
      let!(:project_permission) { FactoryGirl.create(:project_permission, :project_admin, user: current_user, project: project) }
      let!(:resource_permission) { project_permission }

      let(:indexed_data_file) {
        FactoryGirl.create(:data_file, name: "foo", project: project)
      }
      let(:indexed_folder) {
        FactoryGirl.create(:folder, :root, name: "foo", project: project)
      }

      let(:payload) {
        {
          included_kinds: included_kinds,
          search_query: elastic_query
        }
      }

      context 'basic api' do
        it_behaves_like 'an authenticated resource'
        it_behaves_like 'a software_agent accessible resource' do
          let(:expected_response_status) { 201 }
        end
        it_behaves_like 'a listable resource' do
          let(:resource) { indexed_data_file }
          let(:resource_class) { DataFile }
          let(:resource_serializer) { DataFileSerializer }
          let(:unexpected_resources) {
            []
          }
          let(:expected_resources) { [resource] }
          let(:expected_response_status) { 201 }
        end
      end

      context 'single included kind' do
        context 'invalid kind' do
          let(:included_kinds) { ['dds-not-a-kind'] }
          let(:resource_kind) { 'dds-not-a-kind' }
          it_behaves_like 'a kinded resource'
        end

        context 'unindexed kind' do
          let(:included_kinds) { ['dds-project'] }
          let(:resource_class) { Project }
          it_behaves_like 'an indexed resource'
        end

        context 'when user does not have rights to view a result' do
          let(:indexed_data_file) {
            FactoryGirl.create(:data_file, name: "foo", project: other_project)
          }
          let(:expected_response_status) { 201 }

          it 'should return a list that does not include unauthorized resources' do
            is_expected.to eq(expected_response_status)
            expect(response.status).to eq(expected_response_status)
            expect(response.body).to be
            expect(response.body).not_to eq('null')
            expect(response.body).not_to include(DataFileSerializer.new(indexed_data_file).to_json)
          end
        end
      end

      context 'multiple included kinds' do
        let(:included_kinds) { ['dds-folder','dds-file'] }
        let(:expected_response_status) { 201 }

        it 'should return a list of resources' do
          is_expected.to eq(expected_response_status)
          expect(response.status).to eq(expected_response_status)
          expect(response.body).to be
          expect(response.body).not_to eq('null')
          expect(response.body).to include(DataFileSerializer.new(indexed_data_file).to_json)
          expect(response.body).to include(FolderSerializer.new(indexed_folder).to_json)
        end

        context 'invalid kind' do
          let(:included_kinds) { ['dds-not-a-kind', 'dds-folder'] }
          let(:resource_kind) { 'dds-not-a-kind' }
          it_behaves_like 'a kinded resource'
        end

        context 'unindexed kind' do
          let(:included_kinds) { ['dds-project', 'dds-folder'] }
          let(:resource_class) { Project }
          it_behaves_like 'an indexed resource'
        end

        context 'when user does not have rights to view a result' do
          let(:indexed_folder) {
            FactoryGirl.create(:folder, :root, name: "foo", project: other_project)
          }
          let(:expected_response_status) { 201 }

          it 'should return a list of resources excluding unauthorized resources' do
            is_expected.to eq(expected_response_status)
            expect(response.status).to eq(expected_response_status)
            expect(response.body).to be
            expect(response.body).not_to eq('null')
            expect(response.body).to include(DataFileSerializer.new(indexed_data_file).to_json)
            expect(response.body).not_to include(FolderSerializer.new(indexed_folder).to_json)
          end
        end
      end
    end
  end
end
