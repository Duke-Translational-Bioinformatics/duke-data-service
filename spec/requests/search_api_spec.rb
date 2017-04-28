require 'rails_helper'

describe DDS::V1::SearchAPI do

  shared_examples 'a ProvenanceGraphSerializer Serialized endpoint' do |visible_node_syms:,
    non_visible_node_syms: [],
    visible_relationship_syms:,
    non_visible_relationship_syms: []|
    let(:visible_nodes) { visible_node_syms.map{|r| send(r) }.flatten }
    let(:non_visible_nodes) { non_visible_node_syms.map{|r| send(r) }.flatten }
    let(:visible_relationships) { visible_relationship_syms.map{|r| send(r) }.flatten }
    let(:non_visible_relationships) { non_visible_relationship_syms.map{|r| send(r) }.flatten }

    it 'should return properties for all nodes and relationships returned' do
      is_expected.to eq(201)
      expect(response.body).to be
      expect(response.body).not_to eq('null')
      response_json = JSON.parse(response.body)
      expect(response_json).to have_key('graph')
      provenance_graph = response_json['graph']
      expect(provenance_graph).to have_key('nodes')
      expect(provenance_graph['nodes']).not_to be_empty
      visible_nodes.each do |visible_node|
        expected_node = ProvenanceGraphNode.new(visible_node.graph_node)
        expect(provenance_graph['nodes']).to include(
          JSON.parse(ProvenanceGraphNodeSerializer.new(expected_node).to_json)
        )
      end
      non_visible_nodes.each do |non_visible_node|
        expected_node = ProvenanceGraphNode.new(non_visible_node.graph_node)
        expected_node.restricted = true
        expect(provenance_graph['nodes']).to include(
          JSON.parse(ProvenanceGraphNodeSerializer.new(expected_node).to_json)
        )
      end
      expect(provenance_graph).to have_key('relationships')
      expect(provenance_graph['relationships']).not_to be_empty

      visible_relationships.each do |visible_relationship|
        expected_relationship = ProvenanceGraphRelationship.new(visible_relationship.graph_relation)
        expect(provenance_graph['relationships']).to include(
         JSON.parse(ProvenanceGraphRelationshipSerializer.new(expected_relationship).to_json)
        )
      end

      non_visible_relationships.each do |non_visible_relationship|
        expected_relationship = ProvenanceGraphRelationship.new(non_visible_relationship.graph_relation)
        expected_relationship.restricted = true
        expect(provenance_graph['relationships']).to include(
         JSON.parse(ProvenanceGraphRelationshipSerializer.new(expected_relationship).to_json)
        )
      end
    end
  end

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
      subject { post(url, params: payload.to_json, headers: headers) }
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
        it_behaves_like 'a ProvenanceGraphSerializer Serialized endpoint',
          visible_node_syms: [:start_node, :activity, :current_user, :other_file_version],
          visible_relationship_syms: [:activity_used_start_node, :activity_associated_with_current_user, :start_node_derived_from_other_file_version]
      end

      context 'max_hops 1' do
        let(:payload) {{
          start_node: {
            kind: resource_kind,
            id: start_node_id
          },
          max_hops: 1
        }}

        it_behaves_like 'a ProvenanceGraphSerializer Serialized endpoint',
          visible_node_syms: [:start_node, :activity, :other_file_version],
          visible_relationship_syms: [:activity_used_start_node, :start_node_derived_from_other_file_version]
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

        it_behaves_like 'a ProvenanceGraphSerializer Serialized endpoint',
          visible_node_syms: [:start_node, :activity, :current_user],
          non_visible_node_syms: [:other_file_version],
          visible_relationship_syms: [:activity_used_start_node, :start_node_derived_from_other_file_version]
      end
    end
  end

  describe 'Search Provenance wasGeneratedBy' do
    let!(:project) { FactoryGirl.create(:project) }
    let!(:project_permission) { FactoryGirl.create(:project_permission, :project_admin, user: current_user, project: project) }
    let!(:resource_permission) { project_permission }
    let!(:data_file) { FactoryGirl.create(:data_file, project: project) }
    let!(:file_version) { data_file.file_versions.first }
    let(:file_version_id) { file_version.id }
    let!(:activity) { FactoryGirl.create(:activity, creator: current_user) }
    let(:resource_class) { FileVersion }
    let(:resource_kind) { file_version.kind }

    #(file_version)-[was_generated_by]->(activity)
    let!(:activity_generated_file_version) {
      FactoryGirl.create(:generated_by_activity_prov_relation,
        relatable_from: file_version,
        relatable_to: activity
      )
    }

    describe 'POST /api/v1/search/provenance/origin' do
      let(:url) { "/api/v1/search/provenance/origin" }
      subject { post(url, params: payload.to_json, headers: headers) }
      let(:called_action) { 'POST' }

      let(:payload) {{
        file_versions: [
            {
              id: file_version.id
            }
          ]
      }}

      it_behaves_like 'an authenticated resource'
      it_behaves_like 'a software_agent accessible resource' do
        let(:expected_response_status) { 201 }
      end

      context 'when all nodes and relationships accessible by user' do
        it_behaves_like 'a ProvenanceGraphSerializer Serialized endpoint',
          visible_node_syms: [:file_version, :activity],
          visible_relationship_syms: [:activity_generated_file_version]
      end

      context 'when a node is not accessible by user' do
        let!(:other_project) { FactoryGirl.create(:project) }
        let!(:other_file) { FactoryGirl.create(:data_file, project: other_project) }
        let!(:other_file_version) { other_file.file_versions.first }

        # (activity)-[used]->(other_file_version)
        let!(:activity_used_other_file_version) {
          FactoryGirl.create(:used_prov_relation,
            relatable_from: activity,
            relatable_to: other_file_version
          )
        }

        it_behaves_like 'a ProvenanceGraphSerializer Serialized endpoint',
          visible_node_syms: [:file_version, :activity],
          non_visible_node_syms: [:other_file_version],
          visible_relationship_syms: [:activity_generated_file_version, :activity_used_other_file_version]
      end
    end
  end

  describe 'Search Objects' do
    include_context 'elasticsearch prep', [],
    [
      :indexed_folder,
      :indexed_data_file
    ]

    describe 'POST /api/v1/search' do
      let(:url) { "/api/v1/search" }
      subject { post(url, params: payload.to_json, headers: headers) }
      let(:called_action) { 'POST' }
      let(:include_kinds) { ['dds-file'] }
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
          include_kinds: include_kinds,
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
          let(:include_kinds) { ['dds-not-a-kind'] }
          let(:resource_kind) { 'dds-not-a-kind' }
          it_behaves_like 'a kinded resource'
        end

        context 'unindexed kind' do
          let(:include_kinds) { ['dds-project'] }
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
        let(:include_kinds) { ['dds-folder','dds-file'] }
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
          let(:include_kinds) { ['dds-not-a-kind', 'dds-folder'] }
          let(:resource_kind) { 'dds-not-a-kind' }
          it_behaves_like 'a kinded resource'
        end

        context 'unindexed kind' do
          let(:include_kinds) { ['dds-project', 'dds-folder'] }
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
