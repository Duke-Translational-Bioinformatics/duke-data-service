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
    include_context 'mock all Uploads StorageProvider'
    let(:project) { FactoryBot.create(:project) }
    let(:project_permission) { FactoryBot.create(:project_permission, :project_admin, user: current_user, project: project) }
    let(:resource_permission) { project_permission }
    let(:data_file) { FactoryBot.create(:data_file, project: project) }
    let(:start_node) { data_file.file_versions.first }
    let(:start_node_id) { start_node.id }
    let(:activity) { FactoryBot.create(:activity, creator: current_user) }
    let(:resource_class) { FileVersion }
    let(:resource_kind) { start_node.kind }

    # (activity)-(used)->(start_node)
    let(:activity_used_start_node) {
      FactoryBot.create(:used_prov_relation,
        relatable_from: activity,
        relatable_to: start_node
      )
    }

    # (activity)-(asocciatedWith)->(current_user)
    let(:activity_associated_with_current_user) {
      FactoryBot.create(:associated_with_user_prov_relation,
        relatable_from: current_user,
        relatable_to: activity
      )
    }
    let(:deleted_file_version) { FactoryBot.create(:file_version, :deleted, data_file: data_file) }

    before do
      expect(resource_permission).to be_persisted
      expect(activity_used_start_node).to be_persisted
      expect(activity_associated_with_current_user).to be_persisted
      expect(deleted_file_version).to be_persisted
    end
    describe 'POST /api/v1/search/provenance' do
      let(:url) { "/api/v1/search/provenance" }
      subject { post(url, params: payload.to_json, headers: headers) }
      let(:called_action) { 'POST' }
      include_context 'performs enqueued jobs', only: GraphPersistenceJob

      let(:other_file) { FactoryBot.create(:data_file, project: project) }
      let(:other_file_version) { other_file.file_versions.first }

      # (start_node)-(derivedFrom)->(other_file_version)
      let(:start_node_derived_from_other_file_version) {
        FactoryBot.create(:derived_from_file_version_prov_relation,
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

      before do
        expect(other_file).to be_persisted
        expect(other_file_version).to be_persisted
        expect(start_node_derived_from_other_file_version).to be_persisted
      end

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
        let!(:other_project) { FactoryBot.create(:project) }
        let!(:other_file) { FactoryBot.create(:data_file, project: other_project) }
        let!(:other_file_version) { other_file.file_versions.first }

        # (start_node)-(derivedFrom)->(other_file_version)
        let!(:start_node_derived_from_other_file_version) {
          FactoryBot.create(:derived_from_file_version_prov_relation,
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
    include_context 'performs enqueued jobs', only: GraphPersistenceJob
    let!(:project) { FactoryBot.create(:project) }
    let!(:project_permission) { FactoryBot.create(:project_permission, :project_admin, user: current_user, project: project) }
    let!(:resource_permission) { project_permission }
    let!(:data_file) { FactoryBot.create(:data_file, project: project) }
    let!(:file_version) { data_file.file_versions.first }
    let(:file_version_id) { file_version.id }
    let!(:activity) { FactoryBot.create(:activity, creator: current_user) }
    let(:resource_class) { FileVersion }
    let(:resource_kind) { file_version.kind }

    #(file_version)-[was_generated_by]->(activity)
    let!(:activity_generated_file_version) {
      FactoryBot.create(:generated_by_activity_prov_relation,
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
        let!(:other_project) { FactoryBot.create(:project) }
        let!(:other_file) { FactoryBot.create(:data_file, project: other_project) }
        let!(:other_file_version) { other_file.file_versions.first }

        # (activity)-[used]->(other_file_version)
        let!(:activity_used_other_file_version) {
          FactoryBot.create(:used_prov_relation,
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
      let!(:project) { FactoryBot.create(:project) }
      let!(:other_project) { FactoryBot.create(:project) }
      let!(:project_permission) { FactoryBot.create(:project_permission, :project_admin, user: current_user, project: project) }
      let!(:resource_permission) { project_permission }

      let(:indexed_data_file) {
        FactoryBot.create(:data_file, name: "foo", project: project)
      }
      let(:indexed_folder) {
        FactoryBot.create(:folder, :root, name: "foo", project: project)
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
            FactoryBot.create(:data_file, name: "foo", project: other_project)
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
            FactoryBot.create(:folder, :root, name: "foo", project: other_project)
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

    describe 'Search FolderFiles' do
      describe 'POST /api/v1/search/folders_files' do
        let(:url) { "/api/v1/search/folders_files" }
        let!(:project) { FactoryBot.create(:project) }
        let!(:other_project) { FactoryBot.create(:project) }
        let!(:project_permission) { FactoryBot.create(:project_permission, :project_admin, user: current_user, project: project) }
        let!(:resource_permission) { project_permission }

        let(:indexed_data_file) {
          FactoryBot.create(:data_file, name: "foofile", project: project)
        }
        let(:extra_file_one) {
          FactoryBot.create(:data_file, project: project)
        }
        let(:extra_file_two) {
          FactoryBot.create(:data_file, project: project)
        }
        let(:indexed_folder) {
          FactoryBot.create(:folder, :root, name: "foofolder", project: project)
        }
        let(:extra_folder_one) {
          FactoryBot.create(:folder, :root, project: project)
        }
        let(:extra_folder_two) {
          FactoryBot.create(:folder, :root, project: project)
        }

        let(:other_project_indexed_data_file) {
          FactoryBot.create(:data_file, name: "foobyfile", project: other_project)
        }
        let(:other_project_indexed_folder) {
          FactoryBot.create(:folder, :root, name: "foobyfolder", project: other_project)
        }

        context 'no parameters provided' do
          let(:payload) {{}}

          include_context 'elasticsearch prep', [],
          [
            :indexed_folder,
            :indexed_data_file,
            :other_project_indexed_data_file,
            :other_project_indexed_folder,
            :extra_file_one,
            :extra_file_two,
            :extra_folder_one,
            :extra_folder_two
          ]

          it_behaves_like 'a POST request' do
            it_behaves_like 'an authenticated resource'
            it_behaves_like 'a software_agent accessible resource' do
              let(:expected_response_status) { 201}
            end

            it_behaves_like 'a listable resource' do
              let(:resource) { indexed_data_file }
              let(:expected_list_length) { 6 }
              let(:resource_serializer) { Search::DataFileSerializer }
              let(:unexpected_resources) {[
                other_project_indexed_data_file
              ]}
              let(:expected_resources) {[
                indexed_data_file,
                extra_file_one,
                extra_file_two
              ]}
              let(:expected_response_status) { 201 }
            end

            it_behaves_like 'a listable resource' do
              let(:resource) { indexed_folder }
              let(:expected_list_length) { 6 }
              let(:resource_serializer) { Search::FolderSerializer }
              let(:unexpected_resources) {[
                other_project_indexed_folder
              ]}
              let(:expected_resources) {[
                indexed_folder,
                extra_folder_one,
                extra_folder_two
              ]}
              let(:expected_response_status) { 201 }
            end

            it_behaves_like 'a paginated resource' do
              let(:expected_response_status) { 201 }
              let(:expected_total_length) { 6 }
              let(:extras) {[
                extra_file_one,
                extra_file_two,
                extra_folder_one,
                extra_folder_two
              ]}
            end
          end
        end

        context 'filters' do
          let(:payload) {{
            filters: filters
          }}

          include_context 'elasticsearch prep', [],
          [
            :indexed_folder,
            :indexed_data_file,
            :other_project_indexed_data_file,
            :other_project_indexed_folder,
            :extra_file_one,
            :extra_file_two,
            :extra_folder_one,
            :extra_folder_two
          ]

          context 'project.id' do
            context 'all of which user has access' do
              let(:filters) {[
                {'project.id' => [project.id] }
              ]}

              it_behaves_like 'a POST request' do
                it_behaves_like 'a listable resource' do
                  let(:resource) { indexed_data_file }
                  let(:expected_list_length) { 6 }
                  let(:resource_serializer) { Search::DataFileSerializer }
                  let(:unexpected_resources) {[
                    other_project_indexed_data_file
                  ]}
                  let(:expected_resources) {[
                    indexed_data_file,
                    extra_file_one,
                    extra_file_two
                  ]}
                  let(:expected_response_status) { 201 }
                end

                it_behaves_like 'a listable resource' do
                  let(:resource) { indexed_folder }
                  let(:expected_list_length) { 6 }
                  let(:resource_serializer) { Search::FolderSerializer }
                  let(:unexpected_resources) {[
                    other_project_indexed_folder
                  ]}
                  let(:expected_resources) {[
                    indexed_folder,
                    extra_folder_one,
                    extra_folder_two
                  ]}
                  let(:expected_response_status) { 201 }
                end
              end
            end

            context 'all of which user does not have access' do
              let(:filters) {[
                { 'project.id' => [other_project.id] }
              ]}

              it_behaves_like 'a POST request' do
                it_behaves_like 'an authorized resource' do
                  let(:resource_permission) { project_permission }
                end
              end
            end

            context 'mix of projects to which user has and does not have access' do
              let(:filters) {[
                { 'project.id' => [project.id, other_project.id] }
              ]}

              it_behaves_like 'a POST request' do
                it_behaves_like 'an authorized resource' do
                  let(:resource_permission) { project_permission }
                end
              end
            end
          end

          context 'kind' do
            context 'unsupported kind' do
              let(:unsupported_kind) { 'unsupported-kind' }
              let(:filters) {[
                { kind: [unsupported_kind] }
              ]}

              it_behaves_like 'a POST request' do
                it_behaves_like 'a client error' do
                  let(:expected_response) { 400 }
                  let(:expected_reason) { "filters[] kind must be one of #{FolderFilesResponse.supported_filter_kinds.join(', ')}" }
                  let(:expected_suggestion) { "Please supply the correct argument" }
                end
              end
            end

            context 'supported kind' do
              let(:filters) {[
                { kind: ['dds-file'] }
              ]}

              it_behaves_like 'a POST request' do
                it_behaves_like 'a listable resource' do
                  let(:resource) { indexed_data_file }
                  let(:expected_list_length) { 3 }
                  let(:resource_serializer) { Search::DataFileSerializer }
                  let(:unexpected_resources) {
                    [
                      other_project_indexed_data_file
                    ]
                  }
                  let(:expected_resources) {[
                    indexed_data_file,
                    extra_file_one,
                    extra_file_two
                  ]}
                  let(:expected_response_status) { 201 }
                end
              end
            end
          end
        end

        context 'query_string' do
          let(:payload) {{
            query_string: query_string
          }}

          include_context 'elasticsearch prep', [],
          [
            :indexed_folder,
            :indexed_data_file,
            :other_project_indexed_data_file,
            :other_project_indexed_folder,
            :extra_file_one,
            :extra_file_two,
            :extra_folder_one,
            :extra_folder_two
          ]

          context 'query' do
            let(:query_string) {{
              query: 'foo'
            }}

            it_behaves_like 'a POST request' do
              it_behaves_like 'a listable resource' do
                let(:resource) { indexed_data_file }
                let(:expected_list_length) { 2 }
                let(:resource_serializer) { Search::DataFileSerializer }
                let(:unexpected_resources) {[
                  other_project_indexed_data_file,
                  extra_file_one,
                  extra_file_two
                ]}
                let(:expected_resources) {[
                  indexed_data_file
                ]}
                let(:expected_response_status) { 201 }
              end

              it_behaves_like 'a listable resource' do
                let(:resource) { indexed_folder }
                let(:expected_list_length) { 2 }
                let(:resource_serializer) { Search::FolderSerializer }
                let(:unexpected_resources) {[
                  other_project_indexed_folder,
                  extra_folder_one,
                  extra_folder_two
                ]}
                let(:expected_resources) {[
                  indexed_folder
                ]}
                let(:expected_response_status) { 201 }
              end
            end
          end

          context 'fields' do
            context 'unsupported' do
              let(:unsupported_query_field) { 'unsupported-query-field' }
              let(:query_string) {{
                query: 'foo',
                fields: [unsupported_query_field]
              }}

              it_behaves_like 'a POST request' do
                it_behaves_like 'a client error' do
                  let(:expected_response) { 400 }
                  let(:expected_reason) { "query_string.field must be one of #{FolderFilesResponse.supported_query_string_fields.join(', ')}" }
                  let(:expected_suggestion) { "Please supply the correct argument" }
                end
              end
            end

            context 'submitted without query' do
              let(:query_string) {{
                fields: ['name']
              }}

              it_behaves_like 'a POST request' do
                it_behaves_like 'a client error' do
                  let(:expected_response) { 400 }
                  let(:expected_reason) { "query_string.fields is not allowed without query_string.query" }
                  let(:expected_suggestion) { "Please supply the correct argument" }
                end
              end
            end

            context 'supported' do
              let(:query_string) {{
                query: 'foo',
                fields: ['name']
              }}

              it_behaves_like 'a POST request' do
                it_behaves_like 'a listable resource' do
                  let(:resource) { indexed_data_file }
                  let(:expected_list_length) { 2 }
                  let(:resource_serializer) { Search::DataFileSerializer }
                  let(:unexpected_resources) {
                    [
                      other_project_indexed_data_file,
                      extra_file_one,
                      extra_file_two
                    ]
                  }
                  let(:expected_resources) {[
                      indexed_data_file
                  ]}
                  let(:expected_response_status) { 201 }
                end

                it_behaves_like 'a listable resource' do
                  let(:resource) { indexed_folder }
                  let(:expected_list_length) { 2 }
                  let(:resource_serializer) { Search::FolderSerializer }
                  let(:unexpected_resources) {
                    [
                      other_project_indexed_folder,
                      extra_folder_one,
                      extra_folder_two
                    ]
                  }
                  let(:expected_resources) {[
                      indexed_folder
                  ]}
                  let(:expected_response_status) { 201 }
                end
              end
            end
          end
        end

        context 'aggs' do
          let(:payload) {{
            aggs: aggs
          }}

          include_context 'elasticsearch prep', [],
          [
            :indexed_folder,
            :indexed_data_file,
            :other_project_indexed_data_file,
            :other_project_indexed_folder,
            :extra_file_one,
            :extra_file_two,
            :extra_folder_one,
            :extra_folder_two
          ]

          context 'field' do
            context 'not provided in aggs object' do
              let(:aggs) {[
                {name: 'aggname'}
              ]}

              it_behaves_like 'a POST request' do
                it_behaves_like 'a client error' do
                  let(:expected_response) { 400 }
                  let(:expected_reason) { "aggs[].field is required" }
                  let(:expected_suggestion) { "Please supply the correct argument" }
                end
              end
            end

            context 'unsupported' do
              let(:unsupported_agg_field) { 'unsupported-agg' }
              let(:aggs) {[
                {
                  name: 'aggname',
                  field: unsupported_agg_field
                }
              ]}

              it_behaves_like 'a POST request' do
                it_behaves_like 'a client error' do
                  let(:expected_response) { 400 }
                  let(:expected_reason) { "aggs[].field must be one of #{FolderFilesResponse.supported_agg_fields.join(', ')}" }
                  let(:expected_suggestion) { "Please supply the correct argument" }
                end
              end
            end

            context 'supported' do
              let(:aggs) {[
                {
                  name: 'aggname',
                  field: 'project.name'
                }
              ]}

              it_behaves_like 'a POST request' do
                it_behaves_like 'a listable resource' do
                  let(:resource) { indexed_data_file }
                  let(:expected_list_length) { 6 }
                  let(:resource_serializer) { Search::DataFileSerializer }
                  let(:unexpected_resources) {
                    [
                      other_project_indexed_data_file
                    ]
                  }
                  let(:expected_resources) {[
                    indexed_data_file,
                    extra_file_one,
                    extra_file_two
                  ]}
                  let(:expected_response_status) { 201 }
                end

                it_behaves_like 'a listable resource' do
                  let(:resource) { indexed_folder }
                  let(:expected_list_length) { 6 }
                  let(:resource_serializer) { Search::FolderSerializer }
                  let(:unexpected_resources) {
                    [
                      other_project_indexed_folder
                    ]
                  }
                  let(:expected_resources) {[
                    indexed_folder,
                    extra_folder_one,
                    extra_folder_two
                  ]}
                  let(:expected_response_status) { 201 }
                end
              end
            end
          end

          context 'name' do
            context 'not provided in aggs object' do
              let(:aggs) {[
                {field: 'tags.label'}
              ]}

              it_behaves_like 'a POST request' do
                it_behaves_like 'a client error' do
                  let(:expected_response) { 400 }
                  let(:expected_reason) { "aggs[].name is required" }
                  let(:expected_suggestion) { "Please supply the correct argument" }
                end
              end
            end
          end

          context 'size' do
            let(:aggs) {[
              {
                name: 'aggname',
                field: 'project.name',
                size: agg_size
              }
            ]}

            context 'too large' do
              let(:agg_size) { 51 }

              it_behaves_like 'a POST request' do
                it_behaves_like 'a client error' do
                  let(:expected_response) { 400 }
                  let(:expected_reason) { 'aggs[].size must be at least 20 and at most 50' }
                  let(:expected_suggestion) { "Please supply the correct argument" }
                end
              end
            end

            context 'too small' do
              let(:agg_size) { 18 }

              it_behaves_like 'a POST request' do
                it_behaves_like 'a client error' do
                  let(:expected_response) { 400 }
                  let(:expected_reason) { 'aggs[].size must be at least 20 and at most 50' }
                  let(:expected_suggestion) { "Please supply the correct argument" }
                end
              end
            end

            context 'within supported range' do
              let(:agg_size) { 30 }

              it_behaves_like 'a POST request' do
                it_behaves_like 'a listable resource' do
                  let(:resource) { indexed_data_file }
                  let(:expected_list_length) { 6 }
                  let(:resource_serializer) { Search::DataFileSerializer }
                  let(:unexpected_resources) {
                    [
                      other_project_indexed_data_file
                    ]
                  }
                  let(:expected_resources) {[
                    indexed_data_file,
                    extra_file_one,
                    extra_file_two
                  ]}
                  let(:expected_response_status) { 201 }
                end

                it_behaves_like 'a listable resource' do
                  let(:resource) { indexed_folder }
                  let(:expected_list_length) { 6 }
                  let(:resource_serializer) { Search::FolderSerializer }
                  let(:unexpected_resources) {
                    [
                      other_project_indexed_folder
                    ]
                  }
                  let(:expected_resources) {[
                    indexed_folder,
                    extra_folder_one,
                    extra_folder_two
                  ]}
                  let(:expected_response_status) { 201 }
                end
              end
            end
          end
        end

        context 'post_filters' do
          include_context 'elasticsearch prep', [],
          [
            :indexed_folder,
            :indexed_data_file,
            :other_project_indexed_data_file,
            :other_project_indexed_folder,
            :extra_file_one,
            :extra_file_two,
            :extra_folder_one,
            :extra_folder_two
          ]

          context 'without aggs' do
            let(:payload) {{
              post_filters: [{'project.name' => [project.name]}]
            }}

            it_behaves_like 'a POST request' do
              it_behaves_like 'a client error' do
                let(:expected_response) { 400 }
                let(:expected_reason) { "post_filters must be used with aggs" }
                let(:expected_suggestion) { "Please supply the correct argument" }
              end
            end
          end

          context 'with aggs' do
            let(:payload) {{
              aggs: [{
                name: 'aggname',
                field: 'project.name'
              }],
              post_filters: post_filters
            }}

            context 'unsupported' do
              let(:unsupported_post_filter) { 'unsupported-post-filter' }
              let(:post_filters) {[
                { "#{unsupported_post_filter}" => [project.name] }
              ]}

              it_behaves_like 'a POST request' do
                it_behaves_like 'a client error' do
                  let(:expected_response) { 400 }
                  let(:expected_reason) { "post_filters key must be one of #{FolderFilesResponse.supported_agg_fields.join(', ')}" }
                  let(:expected_suggestion) { "Please supply the correct argument" }
                end
              end
            end

            context 'not included in aggs[].field' do
              let(:supported_post_filter) { 'tags.label' }
              let(:post_filters) {[
                { "#{supported_post_filter}" => [project.name] }
              ]}

              it_behaves_like 'a POST request' do
                it_behaves_like 'a client error' do
                  let(:expected_response) { 400 }
                  let(:expected_reason) { "post_filters[#{supported_post_filter}] must be accompanied by aggs[].field #{supported_post_filter}" }
                  let(:expected_suggestion) { "Please supply the correct argument" }
                end
              end
            end

            context 'supported' do
              let(:supported_post_filter) { 'project.name' }
              let(:post_filters) {[
                { "#{supported_post_filter}" => [project.name] }
              ]}

              it_behaves_like 'a POST request' do
                it_behaves_like 'a listable resource' do
                  let(:resource) { indexed_data_file }
                  let(:expected_list_length) { 6 }
                  let(:resource_serializer) { Search::DataFileSerializer }
                  let(:unexpected_resources) {
                    [other_project_indexed_data_file]
                  }
                  let(:expected_resources) { [resource] }
                  let(:expected_response_status) { 201 }
                end

                it_behaves_like 'a listable resource' do
                  let(:resource) { indexed_folder }
                  let(:expected_list_length) { 6 }
                  let(:resource_serializer) { Search::FolderSerializer }
                  let(:unexpected_resources) {
                    [other_project_indexed_folder]
                  }
                  let(:expected_resources) { [resource] }
                  let(:expected_response_status) { 201 }
                end
              end
            end
          end
        end
      end
    end
  end
end
