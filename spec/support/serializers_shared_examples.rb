shared_context 'with auditor' do
  let(:auditor) { FactoryBot.create(:user) }
end

shared_context 'with software_agent' do
  let(:software_agent) {
    FactoryBot.create(:software_agent)
  }
end

shared_context 'creation' do |with_software_agent|
  if with_software_agent
    include_context 'with software_agent'
    let(:created) {
      creation_audit = resource.audits.where(action: 'create').take
      new_comment = creation_audit.comment
      agent_comment = { software_agent_id: software_agent.id }
      if new_comment
        new_comment.merge!(agent_comment)
      else
        new_comment = agent_comment
      end
      creation_audit.update_attributes!(comment: new_comment)
    }
  else
    let(:created) { true }
  end
end

shared_context 'with destroy' do |with_software_agent|
  include_context 'with auditor'
  let(:destroy_action) { '/destroy' }
  if with_software_agent
    include_context 'with software_agent'
    let(:deleted) {
      Audited.audit_class.as_user(auditor) do
        resource.audit_comment = {"action": destroy_action}
        if is_logically_deleted
          resource.update_attribute(:is_deleted, true)
          resource.audits.last.update(comment: {action: 'DELETE', software_agent_id: software_agent.id})
        else
          resource.destroy
          resource.audits.last.update(comment: {action: 'DELETE', software_agent_id: software_agent.id})
        end
      end
    }
  else
    let(:deleted) {
      Audited.audit_class.as_user(auditor) do
        resource.audit_comment = {"action": destroy_action}
        if is_logically_deleted
          resource.update_attribute(:is_deleted, true)
          resource.audits.last.update(comment: {action: 'DELETE'})
        else
          resource.destroy
        end
      end
    }
  end
end

shared_examples 'a json serializer' do
  let(:serializer) { described_class.new resource }
  subject { JSON.parse(serializer.to_json) }

  it 'should serialize to json' do
    expect{subject}.to_not raise_error
  end
end

shared_examples 'a serializer with a serialized audit' do
  # YOU MUST RUN THIS WITHIN A 'a json serializer' shared example block
  include_context 'with auditor'
  before do
    Audited.audit_class.as_user(auditor) do
      expect(resource).to be_persisted
    end
  end

  it 'should serialize with an audit' do
    is_expected.to have_key('audit')
    audit = subject['audit']
    expect(audit).to be
  end

  context 'at creation' do
    before do
      expect(created).to be_truthy
    end

    context 'with browser client' do
      include_context 'creation'

      it 'should report created_by and created_on' do
        is_expected.to have_key('audit')
        audit = subject['audit']
        expect(audit).to have_key("created_on")
        expect(audit).to have_key("created_by")
        creation_audit = resource.audits.where(action: "create").first
        expect(creation_audit).to be
        expect(DateTime.parse(audit["created_on"]).to_i).to be_within(1).of(creation_audit.created_at.to_i)
        if creation_audit.user_id
          creator = User.find(creation_audit.user_id)
          expected_creation_audit = {
            "id" => creator.id,
            "username" => creator.username,
            "full_name" => creator.display_name
          }
          expect(audit["created_by"]).to eq(expected_creation_audit)
        else
          expect(audit["created_by"]).not_to be
        end
      end
    end

    context 'with software_agent' do
      include_context 'creation', 'with software_agent'

      it 'should report agent in created_by' do
        is_expected.to have_key('audit')
        audit = subject['audit']
        expect(audit).to have_key("created_on")
        expect(audit).to have_key("created_by")
        creation_audit = resource.audits.where(action: "create").first
        expect(creation_audit).to be
        expect(DateTime.parse(audit["created_on"]).to_i).to be_within(1).of(creation_audit.created_at.to_i)
        if creation_audit.user_id
          creator = User.find(creation_audit.user_id)
          expected_creation_audit = {
            "id" => creator.id,
            "username" => creator.username,
            "full_name" => creator.display_name,
            "agent" => {
              "id" => software_agent.id,
              "name" => software_agent.name
            }
          }
          expect(audit["created_by"]).to eq(expected_creation_audit)
        else
          expect(audit["created_by"]).not_to be
        end
      end
    end
  end

  context 'for an updated resource' do
    include_context 'with auditor'
    let(:update_attribute) { 'updated_at' }
    let(:update_value) { DateTime.now }
    let(:update_action) { '/update' }
    before(:each) do
      ApplicationAudit.current_comment = audit_comment
      ApplicationAudit.current_user = auditor
      resource.update_attributes!(
        update_attribute => update_value,
        :audit_comment => audit_comment
      )
    end

    context 'with browser client' do
      let(:audit_comment) { {
        "action": update_action
      } }

      it 'should report last_updated_on and last_updated_by' do
        is_expected.to have_key('audit')
        audit = subject['audit']
        expect(audit).to have_key("last_updated_on")
        expect(audit).to have_key("last_updated_by")
        last_update_audit = resource.audits.where(action: "update").last
        expect(last_update_audit).to be
        expect(DateTime.parse(audit["last_updated_on"]).to_i).to be_within(1).of(last_update_audit.created_at.to_i)
        updator = User.find(last_update_audit.user_id)
        expected_update_audit = {
          "id" => updator.id,
          "username" => updator.username,
          "full_name" => updator.display_name
        }
        expect(audit["last_updated_by"]).to eq(expected_update_audit)
      end
    end

    context 'with software_agent' do
      include_context 'with software_agent'
      let(:audit_comment) { {
        "action": update_action,
        "software_agent_id": software_agent.id
      } }

      it 'should report agent in last_updated_by' do
        is_expected.to have_key('audit')
        audit = subject['audit']
        expect(audit).to have_key("last_updated_on")
        expect(audit).to have_key("last_updated_by")
        last_update_audit = resource.audits.where(action: "update").last
        expect(last_update_audit).to be
        expect(DateTime.parse(audit["last_updated_on"]).to_i).to be_within(1).of(last_update_audit.created_at.to_i)
        updator = User.find(last_update_audit.user_id)
        expected_update_audit = {
          "id" => updator.id,
          "username" => updator.username,
          "full_name" => updator.display_name,
          "agent" => {
            "id" => software_agent.id,
            "name" => software_agent.name
          }
        }
        expect(audit["last_updated_by"]).to eq(expected_update_audit)
      end
    end
  end

  context 'for a deleted resource' do
    before do
      expect(deleted).to be_truthy
    end

    context 'with browser client' do
      include_context 'with destroy'

      it 'should report deleted_on and deleted_by' do
        is_expected.to have_key('audit')
        audit = subject['audit']
        expect(audit).to have_key("deleted_on")
        expect(audit).to have_key("deleted_by")
        delete_audit = is_logically_deleted ?
          resource.audits.where(action: "update").where('comment @> ?', {action: 'DELETE'}.to_json).first :
          resource.audits.where(action: "destroy").first
        expect(delete_audit).to be
        expect(DateTime.parse(audit["deleted_on"]).to_i).to be_within(1).of(delete_audit.created_at.to_i)
        deleter = User.find(delete_audit.user_id)
        expected_deletion_audit = {
          "id" => deleter.id,
          "username" => deleter.username,
          "full_name" => deleter.display_name
        }
        expect(audit["deleted_by"]).to eq(expected_deletion_audit)
      end
    end

    context 'with software_agent' do
      include_context 'with destroy', 'with software_agent'

      it 'should report agent in deleted_by' do
        is_expected.to have_key('audit')
        audit = subject['audit']
        expect(audit).to have_key("deleted_on")
        expect(audit).to have_key("deleted_by")
        delete_audit = is_logically_deleted ?
          resource.audits.where(action: "update").where('comment @> ?', {action: 'DELETE'}.to_json).first :
          resource.audits.where(action: "destroy").first
        expect(delete_audit).to be
        expect(DateTime.parse(audit["deleted_on"]).to_i).to be_within(1).of(delete_audit.created_at.to_i)
        deleter = User.find(delete_audit.user_id)
        expected_deletion_audit = {
          "id" => deleter.id,
          "username" => deleter.username,
          "full_name" => deleter.display_name,
          "agent" => {
            "id" => software_agent.id,
            "name" => software_agent.name
          }
        }
        expect(audit["deleted_by"]).to eq(expected_deletion_audit)
      end
    end
  end
end

shared_examples 'a has_one association with' do |name, serialized_with, root: name|
  it "#{name} serialized using #{serialized_with}" do
    expect(described_class._reflections).to have_key(root)
    expect(described_class._reflections[root].name).to eq(name)
    expect(described_class._reflections[root]).to be_a(ActiveModel::Serializer::HasOneReflection)
    expect(described_class._reflections[root].options[:serializer]).to eq(serialized_with)
  end
end

shared_examples 'a has_many association with' do |name, serialized_with, root: name|
  it "#{name} serialized using #{serialized_with}" do
    expect(described_class._reflections).to have_key(root)
    expect(described_class._reflections[root].name).to eq(name)
    expect(described_class._reflections[root]).to be_a(ActiveModel::Serializer::HasManyReflection)
    expect(described_class._reflections[root].options[:serializer]).to eq(serialized_with)
  end
end

shared_examples 'a ProvRelationSerializer' do |from:, to:|
  let(:is_logically_deleted) { true }
  include_context 'performs enqueued jobs', only: GraphPersistenceJob

  it_behaves_like 'a has_one association with', :relatable_from, from, root: :from
  it_behaves_like 'a has_one association with', :relatable_to, to, root: :to

  it_behaves_like 'a json serializer' do
    it 'should have expected keys and values' do
      is_expected.to have_key('kind')
      expect(subject["kind"]).to eq(resource.kind)
      is_expected.to have_key('id')
      expect(subject['id']).to eq(resource.id)
      is_expected.to have_key('from')
      is_expected.to have_key('to')
    end
    it_behaves_like 'a serializer with a serialized audit'
  end
end

shared_examples 'a serialized DataFile' do |resource_sym, with_label: false|
  let(:resource) { send(resource_sym) }
  let(:is_logically_deleted) { true }
  let(:expected_attributes) {{
    'id' => resource.id,
    'parent' => { 'kind' => resource.parent.kind,
                  'id' => resource.parent_id
                },
    'name' => resource.name,
    'is_deleted' => resource.is_deleted
  }}

  it_behaves_like 'a has_one association with', :current_file_version, FileVersionPreviewSerializer, root: :current_version
  it_behaves_like 'a has_one association with', :project, ProjectPreviewSerializer
  it_behaves_like 'a has_many association with', :ancestors, AncestorSerializer

  it_behaves_like 'a json serializer' do
    it { is_expected.to include(expected_attributes) }
    it { is_expected.not_to have_key('upload') }
    unless with_label
      it { is_expected.not_to have_key('label') }
    end

    it_behaves_like 'a serializer with a serialized audit'
  end
end

shared_examples 'a serialized Folder' do |resource_sym, with_parent: false|
  let (:resource) { send(resource_sym) }
  let(:is_logically_deleted) { true }
  let(:expected_attributes) {{
    'id' => resource.id,
    'parent' => parent,
    'name' => resource.name,
    'is_deleted' => resource.is_deleted
  }}

  if with_parent
    let(:parent) {{
      'kind' => resource.parent.kind,
      'id' => resource.parent.id
    }}
  else
    let(:parent) {{
      'kind' => resource.project.kind,
      'id' => resource.project.id
    }}
  end

  it_behaves_like 'a has_one association with', :project, ProjectPreviewSerializer
  it_behaves_like 'a has_many association with', :ancestors, AncestorSerializer

  it_behaves_like 'a json serializer' do
    it { is_expected.to include(expected_attributes) }
  end
end
