require 'rails_helper'

RSpec.describe ElasticsearchResponse do
  let(:indexed_data_file) {
    FactoryGirl.create(:data_file, name: "foo bar")
  }
  let(:tag) { FactoryGirl.create(:tag, taggable: indexed_data_file) }
  let(:indexed_folder) {
    FactoryGirl.create(:folder, name: "foo bar")
  }
  let(:all_projects) {
    {'project.id' => [
      indexed_folder.project.id,
      indexed_data_file.project.id
    ]}
  }
  subject { described_class.new }

  it { expect(described_class).to include(ActiveModel::Serialization) }

  describe '::indexed_models' do
    let(:expected_indexed_models) {[DataFile, Folder]}
    it { expect(described_class).to respond_to(:indexed_models) }
    it { expect(described_class.indexed_models).to be_an Array   }
    it { expect(described_class.indexed_models.length).to eq(expected_indexed_models.length) }
    it {
      expected_indexed_models.each do |expected_indexed_model|
        expect(described_class.indexed_models).to include expected_indexed_model
      end
    }
  end

  describe '::supported_query_string_fields' do
    let (:expected_query_string_fields) { ['name', 'tags.label'] }
    it { expect(described_class).to respond_to(:supported_query_string_fields) }
    it { expect(described_class.supported_query_string_fields).to be_an Array  }
    it { expect(described_class.supported_query_string_fields.length).to eq(expected_query_string_fields.length) }
    it {
      expected_query_string_fields.each do |expected_query_string_field|
        expect(described_class.supported_query_string_fields).to include expected_query_string_field
      end
    }
  end

  describe '::supported_filter_keys' do
    let(:expected_supported_filter_keys) { ['kind', 'project.id'] }
    it { expect(described_class).to respond_to(:supported_filter_keys) }
    it { expect(described_class.supported_filter_keys).to be_an Array  }
    it { expect(described_class.supported_filter_keys.length).to eq(expected_supported_filter_keys.length) }
    it {
      expected_supported_filter_keys.each do |expected_filter_key|
        expect(described_class.supported_filter_keys).to include expected_filter_key
      end
    }
  end

  describe '::supported_filter_kinds' do
    let (:expected_supported_filter_kinds) { ['dds-file', 'dds-folder'] }
    it { expect(described_class).to respond_to(:supported_filter_kinds) }
    it { expect(described_class.supported_filter_kinds).to be_an Array  }
    it { expect(described_class.supported_filter_kinds.length).to eq(expected_supported_filter_kinds.length) }
    it {
      expected_supported_filter_kinds.each do |expected_filter_kind|
        expect(described_class.supported_filter_kinds).to include expected_filter_kind
      end
    }
  end

  describe '::supported_agg_fields' do
    let (:expected_agg_fields) { ['project.name', 'tags.label'] }
    it { expect(described_class).to respond_to(:supported_agg_fields) }
    it { expect(described_class.supported_agg_fields).to be_an Array  }
    it { expect(described_class.supported_agg_fields.length).to eq(expected_agg_fields.length) }
    it {
      expected_agg_fields.each do |expected_agg_field|
        expect(described_class.supported_agg_fields).to include expected_agg_field
      end
    }
  end

  describe '#filter' do
    it { is_expected.to respond_to(:filter).with(0).arguments }
    it {
      object = subject.filter(nil)
      expect(object).to eq(subject)
    }

    it { is_expected.to respond_to(:filter).with(1).argument }
    it {
      object = subject.filter([all_projects])
      expect(object).to eq(subject)
    }
  end

  describe '#query' do
    let(:query_string) {{query: "foo"}}
    it { is_expected.to respond_to(:query).with(0).arguments }
    it {
      object = subject.query(nil)
      expect(object).to eq(subject)
    }

    it { is_expected.to respond_to(:query).with(1).argument }
    it {
      object = subject.query(query_string)
      expect(object).to eq(subject)
    }
  end

  describe '#aggregate' do
    let(:agg) {{field: 'tags.label', name: Faker::Beer.hop}}
    it { is_expected.to respond_to(:aggregate).with(0).arguments }
    it {
      object = subject.aggregate(nil)
      expect(object).to eq(subject)
    }

    it { is_expected.to respond_to(:aggregate).with(1).argument }
    it {
      object = subject.aggregate([agg])
      expect(object).to eq(subject)
    }
  end

  describe '#post_filter' do
    let(:post_filter) {{"project.name" => [indexed_folder.project.name] }}

    it { is_expected.to respond_to(:post_filter).with(0).arguments }
    it {
      object = subject.post_filter(nil)
      expect(object).to eq(subject)
    }

    it { is_expected.to respond_to(:post_filter).with(1).argument }
    it {
      object = subject.post_filter([post_filter])
      expect(object).to eq(subject)
    }
  end

  describe 'pagination support' do
    it { is_expected.to respond_to(:page) }
    it { is_expected.to respond_to(:per) }
    it { is_expected.to respond_to(:padding) }

    it { is_expected.to respond_to(:elastic_response) }
    it { is_expected.to delegate_method(:total_count).to(:elastic_response) }
    it { is_expected.to delegate_method(:total_pages).to(:elastic_response) }
    it { is_expected.to delegate_method(:limit_value).to(:elastic_response) }
    it { is_expected.to delegate_method(:current_page).to(:elastic_response) }
    it { is_expected.to delegate_method(:next_page).to(:elastic_response) }
    it { is_expected.to delegate_method(:prev_page).to(:elastic_response) }
  end

  describe 'minimum supported search' do
    it { is_expected.to respond_to(:results) }
    it { is_expected.to respond_to(:aggs) }

    let(:expected_query) {{
      query: {
        filtered: {
          filter: {
            bool: {
              must: [
                { terms: { "project.id.raw" => all_projects['project.id'] } }
              ]
            }
          }
        }
      }
    }}
    include_context 'elasticsearch prep', [:indexed_data_file, :indexed_folder], [:indexed_data_file, :indexed_folder]

    before do
      subject.filter([all_projects])
    end

    describe '#search' do
      it 'should return the ElasticsearchResponse instance modified with results' do
        response = subject.search
        expect(response).to eq(subject)
        expect(response.results).not_to be_empty
        response.results.each do |result|
          expect(all_projects['project.id']).to include result[:project][:id]
        end
      end
    end

    describe 'paginated' do
      it 'chained page, per, and padding should mutate the base object' do
        response = subject.search
        chained = response.page(1).per(1).padding(1)
        expect(chained).to eq(response)
        expect(chained).to eq(response)
        expect(chained.total_count).to eq(chained.elastic_response.total_count)
        expect(chained.total_pages).to eq(chained.elastic_response.total_pages)
        expect(chained.limit_value).to eq(chained.elastic_response.limit_value)
        expect(chained.current_page).to eq(chained.elastic_response.current_page)
        expect(chained.next_page).to eq(chained.elastic_response.next_page)
        expect(chained.prev_page).to eq(chained.elastic_response.prev_page)
        expect(chained.results).not_to be_empty
        expect(chained.results.length).to eq 1
      end
    end

    it {
      is_expected.to receive(:search_definition).with(expected_query).and_call_original
      expect {
        subject.search
      }.not_to raise_error
    }
  end

  describe 'filters' do
    context 'missing \'project.id\'' do
      it {
        is_expected.not_to receive(:search_definition)
        expect{
          subject.search
        }.to raise_error(ArgumentError)
      }
    end

    describe 'kind' do
      context 'unsupported kind' do
        let(:kind_filter) {
          [
            all_projects,
            {"kind" => ["dds-project"]}
          ]
        }

        it {
          subject.filter(kind_filter)
          is_expected.not_to receive(:search_definition)
          expect {
            subject.search
          }.to raise_error(ArgumentError)
        }
      end

      context 'supported kind' do
        it {
          described_class.supported_filter_kinds.each do |supported_kind|
            expect {
              expected_query = {
                query: {
                  filtered: {
                    filter: {
                      bool: {
                        must: [
                          { terms: { "project.id.raw" => all_projects['project.id'] } },
                          { terms: { "kind.raw" => [supported_kind] }  }
                        ]
                      }
                    }
                  }
                }
              }
              er = described_class.new
              er.filter([all_projects , {"kind" => [supported_kind]}])
              expect(er).to receive(:search_definition).with(expected_query)
              er.search
            }.not_to raise_error
          end
        }
      end
    end
  end

  describe 'query_string' do
    describe 'query' do
      let(:query_string) {{
        query: query
      }}

      before do
        subject.filter([all_projects])
        subject.query(query_string)
      end

      context 'without whitespace' do
        let(:query) { indexed_folder.name.split(' ')[0] }
        let(:expected_query) {{
          query: {
            filtered: {
              filter: {
                bool: {
                  must: [
                    { terms: { "project.id.raw" => all_projects['project.id'] } }
                  ]
                }
              },
              query: {
                query_string: {
                  fields: described_class.supported_query_string_fields,
                  query: "*#{query}*"
                }
              }
            }
          }
        }}
        include_context 'elasticsearch prep', [:indexed_data_file, :indexed_folder], [:indexed_data_file, :indexed_folder]

        it {
          is_expected.to receive(:search_definition).with(expected_query)
          expect {
            subject.search
          }.not_to raise_error
        }
      end

      context 'with white spaces' do
        let(:query) { indexed_folder.name }
        let(:expected_query) {{
          query: {
            filtered: {
              filter: {
                bool: {
                  must: [
                    { terms: { "project.id.raw" => all_projects['project.id'] } }
                  ]
                }
              },
              query: {
                query_string: {
                  query: "*#{query}* *#{query.gsub(/\s/,'* *')}*",
                  fields: described_class.supported_query_string_fields
                }
              }
            }
          }
        }}
        include_context 'elasticsearch prep', [:indexed_data_file, :indexed_folder], [:indexed_data_file, :indexed_folder]

        it {
          is_expected.to receive(:search_definition).with(expected_query)
          expect {
            subject.search
          }.not_to raise_error
        }
      end

      context 'provided without fields' do
        let(:query) { indexed_folder.name[0,2] }
        let(:expected_query) {{
          query: {
            filtered: {
              query: {
                query_string: {
                  query: "*#{query}*",
                  fields: described_class.supported_query_string_fields
                }
              },
              filter: {
                bool: {
                  must: [
                    { terms: { "project.id.raw" => all_projects['project.id'] } }
                  ]
                }
              }
            }
          }
        }}
        include_context 'elasticsearch prep', [:indexed_data_file, :indexed_folder], [:indexed_data_file, :indexed_folder]

        it {
          is_expected.to receive(:search_definition).with(expected_query)
          expect {
            subject.search
          }.not_to raise_error
        }
      end
    end

    describe 'fields' do
      context 'unsupported field' do
        let(:field) { 'unsupported' }
        let(:query) { indexed_folder.name[0,2] }
        let(:query_string) {
          {
            query: query,
            fields: [ field ]
          }
        }

        before do
          subject.filter([all_projects])
          subject.query(query_string)
        end

        it {
          is_expected.not_to receive(:search_definition)
          expect{
            subject.search
          }.to raise_error(ArgumentError)
        }
      end

      context 'supported' do
        let(:query_lookup) {{
          'name' => indexed_folder.name[0,2],
          'tags.label' => tag.label[0,2]
        }}

        it {
          described_class.supported_query_string_fields.each do |supported_field|
            expected_query = {
              query: {
                filtered: {
                  query: {
                    query_string: {
                      fields: [supported_field],
                      query: "*#{query_lookup[supported_field]}*"
                    }
                  },
                  filter: {
                    bool: {
                      must: [
                        { terms: { "project.id.raw" => all_projects['project.id'] } }
                      ]
                    }
                  }
                }
              }
            }

            er = described_class.new
            er.filter([all_projects])
            er.query({
              query: query_lookup[supported_field],
              fields: [ supported_field ]
            })
            expect(er).to receive(:search_definition).with(expected_query)
            expect {
              er.search
            }.not_to raise_error
          end
        }
      end

      context 'provided without query' do
        let(:query_string) {
          {
            fields: described_class.supported_query_string_fields
          }
        }

        before do
          subject.filter([all_projects])
          subject.query(query_string)
        end

        it {
          is_expected.not_to receive(:search_definition)
          expect {
            subject.search
          }.to raise_error(ArgumentError)
        }
      end
    end
  end

  describe 'aggs' do
    context 'field' do
      context 'not provided' do
        let(:agg_name) { 'project_name' }
        let(:aggs) {
          [{ name: agg_name }]
        }

        before do
          subject.filter([all_projects])
          subject.aggregate(aggs)
        end

        it {
          is_expected.not_to receive(:search_definition)
          expect {
            subject.search
          }.to raise_error(ArgumentError)
        }
      end

      context 'unsupported agg field' do
        let(:agg_name) { 'project_name' }
        let(:aggs) {
          [
            {field: 'unsupported', name: agg_name}
          ]
        }

        before do
          subject.filter([all_projects])
          subject.aggregate(aggs)
        end
        it {
          is_expected.not_to receive(:search_definition)
          expect {
            subject.search
          }.to raise_error(ArgumentError)
        }
      end

      context 'supported agg field' do
        it {
          described_class.supported_agg_fields.each do |supported_agg_field|
            field_name = Faker::Beer.hop
            expected_query = {
              query: {
                filtered: {
                  filter: {
                    bool: {
                      must: [
                        { terms: { "project.id.raw" => all_projects['project.id'] } }
                      ]
                    }
                  }
                }
              },
              aggs: {
                field_name => {
                  terms: {
                    field: "#{supported_agg_field}.raw",
                    size: 20
                  }
                }
              }
            }

            er = described_class.new
            er.filter([all_projects])
            er.aggregate([
              {field: supported_agg_field, name: field_name}
            ])
            expect(er).to receive(:search_definition).with(expected_query)
            expect {
              er.search
            }.not_to raise_error
          end
        }
      end
    end

    context 'name' do
      let(:field) { described_class.supported_agg_fields.first }

      context 'not provided' do
        let(:aggs) {
          [
            {field: field}
          ]
        }

        before do
          subject.filter([all_projects])
          subject.aggregate(aggs)
        end
        it {
          is_expected.not_to receive(:search_definition)
          expect {
            subject.search
          }.to raise_error(ArgumentError)
        }
      end

      context 'provided' do
        let(:field_name) { Faker::Beer.hop }
        let(:aggs) {
          [
            {field: field, name: field_name}
          ]
        }
        let(:expected_query) {{
          query: {
            filtered: {
              filter: {
                bool: {
                  must: [
                    { terms: { "project.id.raw" => all_projects['project.id'] } }
                  ]
                }
              }
            }
          },
          aggs: {
            field_name => {
              terms: {
                field: "#{field}.raw",
                size: 20
              }
            }
          }
        }}
        include_context 'elasticsearch prep', [:indexed_data_file, :indexed_folder], [:indexed_data_file, :indexed_folder]

        before do
          subject.filter([all_projects])
          subject.aggregate(aggs)
        end
        it {
            is_expected.to receive(:search_definition).with(expected_query)
            expect {
                subject.search
            }.not_to raise_error
        }
      end
    end

    context 'size' do
      let(:default_size) { 20 }
      let(:field_name) { Faker::Beer.hop }
      let(:field) { described_class.supported_agg_fields.first }

      context 'not provided' do
        let(:aggs) {
          [
            {field: field, name: field_name}
          ]
        }
        let(:expected_query) {{
          query: {
            filtered: {
              filter: {
                bool: {
                  must: [
                    { terms: { "project.id.raw" => all_projects['project.id'] } }
                  ]
                }
              }
            }
          },
          aggs: {
            field_name => {
              terms: {
                field: "#{field}.raw",
                size: default_size
              }
            }
          }
        }}
        include_context 'elasticsearch prep', [:indexed_data_file, :indexed_folder], [:indexed_data_file, :indexed_folder]

        before do
          subject.filter([all_projects])
          subject.aggregate(aggs)
        end
        it {
          is_expected.to receive(:search_definition).with(expected_query)
          expect {
              subject.search
          }.not_to raise_error
        }
      end

      context '> 50' do
        let(:aggs) {
          [
            {field: field, name: field_name, size: 51}
          ]
        }

        before do
          subject.filter([all_projects])
          subject.aggregate(aggs)
        end
        it {
          is_expected.not_to receive(:search_definition)
          expect {
            subject.search
          }.to raise_error(ArgumentError)
        }
      end

      context '20 <= size < 50' do
        let(:size) { 30 }
        let(:aggs) {
          [
            {field: field, name: field_name, size: size}
          ]
        }
        let(:expected_query) {{
          query: {
            filtered: {
              filter: {
                bool: {
                  must: [
                    { terms: { "project.id.raw" => all_projects['project.id'] } }
                  ]
                }
              }
            }
          },
          aggs: {
            field_name => {
              terms: {
                field: "#{field}.raw",
                size: size
              }
            }
          }
        }}
        include_context 'elasticsearch prep', [:indexed_data_file, :indexed_folder], [:indexed_data_file, :indexed_folder]

        before do
          subject.filter([all_projects])
          subject.aggregate(aggs)
        end
        it {
          is_expected.to receive(:search_definition).with(expected_query)
          expect {
            subject.search
          }.not_to raise_error
        }
      end
    end
  end

  describe 'post_filters' do
    context 'provided without aggs' do
      let(:post_filters) {
        [
          {"project.name" => [indexed_folder.project.name] }
        ]
      }
      let(:aggs) { nil }

      before do
        subject.filter([all_projects])
        subject.aggregate(aggs)
        subject.post_filter(post_filters)
      end
      it {
        is_expected.not_to receive(:search_definition)
        expect {
            subject.search
        }.to raise_error(ArgumentError)
      }
    end

    context 'unsupported' do
      let(:aggs) {
        [{field: 'project.name', name: 'project_names'}]
      }
      let(:post_filters) {
        [
          {"unsupported" => [Faker::Beer.hop] }
        ]
      }

      before do
        subject.filter([all_projects])
        subject.aggregate(aggs)
        subject.post_filter(post_filters)
      end
      it {
        is_expected.not_to receive(:search_definition)
        expect {
          subject.search
        }.to raise_error(ArgumentError)
      }
    end

    context 'not matching submitted aggs field' do
      let(:aggs) {
        [{field: 'project.name', name: 'project_names'}]
      }
      let(:post_filters) {
        [
          {"tags.label" => [Faker::Beer.hop] }
        ]
      }

      before do
        subject.filter([all_projects])
        subject.aggregate(aggs)
        subject.post_filter(post_filters)
      end
      it {
        is_expected.not_to receive(:search_definition)
        expect {
          subject.search
        }.to raise_error(ArgumentError)
      }
    end

    context 'supported' do
      let(:field_value_lookup) {{
        "project.name" => {
          agg_name: 'project_name',
          value: [indexed_folder.project.name],
          size: 20
        },
        "tags.label" => {
          agg_name: 'tags',
          value: [tag.label],
          size: 30
        }
      }}
      it {
        described_class.supported_agg_fields.each do |supported_post_filter_field|
          search_value = field_value_lookup[supported_post_filter_field][:value]
          agg_name = field_value_lookup[supported_post_filter_field][:agg_name]
          size = field_value_lookup[supported_post_filter_field][:size]
          expected_query = {
            query: {
              filtered: {
                filter: {
                  bool: {
                    must: [
                      { terms: { "project.id.raw" => all_projects['project.id'] } }
                    ]
                  }
                }
              }
            },
            aggs: {
              agg_name => {
                terms: {
                  field: "#{supported_post_filter_field}.raw",
                  size: size
                }
              }
            },
            post_filter: {
              bool: {
                must: [
                  {terms: {"#{supported_post_filter_field}.raw" => search_value}}
                ]
              }
            }
          }

          er = described_class.new
          er.filter([all_projects])
          er.aggregate([
            {field: supported_post_filter_field, name: agg_name, size: size}
          ])
          er.post_filter([
            {supported_post_filter_field => search_value }
          ])
          expect(er).to receive(:search_definition).with(expected_query)
          expect {
            er.search
          }.not_to raise_error
        end
      }
    end
  end

  describe 'combination query' do
    let(:query) { tag.label[0,2] }
    let(:query_field) { 'tags.label' }
    let(:query_string) {{ query: query, fields: [query_field] }}
    let(:kind) { 'dds-file' }
    let(:filters) {[
      all_projects,
      {"kind" => [kind]}
    ]}
    let(:project_name_agg_field) { 'project.name' }
    let(:project_name_agg_name) { Faker::Beer.hop }
    let(:project_name_agg_size) { 20 }
    let(:tag_agg_field) { 'tags.label' }
    let(:tag_agg_name) { Faker::Beer.hop }
    let(:tagg_agg_size) { 30 }
    let(:aggs) {[
      {field: project_name_agg_field, name: project_name_agg_name, size: project_name_agg_size},
      {field: tag_agg_field, name: tag_agg_name, size: tagg_agg_size},
    ]}
    let(:post_filter_project_value) { indexed_data_file.project.name }
    let(:post_filter_tag_value) { tag.label }
    let(:post_filters) {
      [
        {project_name_agg_field => post_filter_project_value },
        {tag_agg_field => post_filter_tag_value }
      ]
    }
    let(:expected_query) {
      {
        query: {
          filtered: {
            filter: {
              bool: {
                must: [
                  { terms: { "project.id.raw" => all_projects['project.id'] } },
                  { terms: { "kind.raw" => [kind] }  }
                ]
              }
            },
            query: {
              query_string: {
                query: "*#{query}*",
                fields: [query_field]
              }
            }
          }
        },
        aggs: {
          project_name_agg_name => {
            terms: {
              field: "#{project_name_agg_field}.raw",
              size: project_name_agg_size
            }
          },
          tag_agg_name => {
            terms: {
              field: "#{tag_agg_field}.raw",
              size: tagg_agg_size
            }
          }
        },
        post_filter: {
          bool: {
            must: [
              {terms: {"#{project_name_agg_field}.raw" => post_filter_project_value}},
              {terms: {"#{tag_agg_field}.raw" => post_filter_tag_value}}
            ]
          }
        }
      }
    }
    include_context 'elasticsearch prep', [:indexed_data_file, :indexed_folder], [:indexed_data_file, :indexed_folder]

    it {
      subject.query query_string
      subject.filter filters
      subject.aggregate aggs
      subject.post_filter post_filters

      is_expected.to receive(:search_definition).with(expected_query)
      expect {
        subject.search
      }.not_to raise_error
    }
  end
 end
