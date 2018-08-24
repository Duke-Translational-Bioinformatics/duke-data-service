require 'rails_helper'
RSpec.describe AuditSummarySerializer do
  let(:dummy_serializer) {
    Class.new {
      include AuditSummarySerializer
      attr_reader :object
      def initialize(audited_object)
        @object = audited_object
      end
    }
  }
  subject {
    Audited.audit_class.as_user(auditor) {
      dummy_serializer.new(audited_object).audit
    }
  }

  shared_context 'current_user' do
    include_context 'with auditor'

    before do
      ApplicationAudit.current_user = auditor
    end
    after do
      ApplicationAudit.clear_store
    end
  end

  shared_context 'current_user.current_software_agent' do
    include_context 'current_user'
    include_context 'with software_agent'
    before do
      auditor.current_software_agent = software_agent
    end
  end

  shared_context 'update event' do
    before do
      Audited.audit_class.as_user(auditor) do
        audited_object.update_attributes!(
          "#{update_attribute}": update_value,
          audit_comment:  {"action": update_action}
        )
      end
    end
  end

  shared_context 'deletion event' do
    before do
      Audited.audit_class.as_user(auditor) do
        audited_object.destroy
      end
    end
  end

  shared_context 'logical deletion event' do
    before do
      Audited.audit_class.as_user(auditor) do
        audited_object.update_attributes!(
          is_deleted: true,
          audit_comment: {"action": 'DELETE'}
        )
      end
    end
  end

  shared_context 'restoration event' do
    before do
      Audited.audit_class.as_user(auditor) do
        audited_object.update_attributes!(
          is_deleted: true,
          audit_comment: {"action": 'DELETE'}
        )
      end
      Audited.audit_class.as_user(auditor) do
        audited_object.update_attributes!(
          is_deleted: false,
          audit_comment: {"endpoint": '/api/v1/trashbin/restore'}
        )
      end
    end
  end

  shared_context 'purge event' do
    before do
      Audited.audit_class.as_user(auditor) do
        audited_object.update_attributes!(
          is_deleted: true,
          audit_comment: {"action": 'DELETE'}
        )
      end
      Audited.audit_class.as_user(auditor) do
        audited_object.update_attributes!(
          is_purged: true,
          audit_comment: {"endpoint": '/api/v1/trashbin/purge'}
        )
      end
    end
  end

  context 'standard audited model' do
    let(:audited_object) { FactoryBot.create(:affiliation) }

    context 'created' do
      let(:expected_audit) {
        audited_object.audits.first
      }
      context 'with user not using software_agent' do
        include_context 'current_user'
        let(:expected_audit_summary) {
        {
          created_on:  expected_audit.created_at,
          created_by:  expected_audit.user.audited_user_info,
          last_updated_on: nil,
          last_updated_by: nil,
          deleted_on: nil,
          deleted_by: nil
        }}
        it {
          is_expected.to eq expected_audit_summary
        }
      end
      context 'with user using software_agent' do
        include_context 'current_user.current_software_agent'
        let(:expected_audit_summary) {
        {
          created_on:  expected_audit.created_at,
          created_by:  expected_audit.user.audited_user_info.merge!(
          {
            "agent": {
              "id": software_agent.id,
              "name": software_agent.name
            }
          }),
          last_updated_on: nil,
          last_updated_by: nil,
          deleted_on: nil,
          deleted_by: nil
        }}
        it {
          is_expected.to eq expected_audit_summary
        }
      end
    end

    context 'updated' do
      let(:update_attribute) { :project_role_id }
      let(:update_value) { SecureRandom.uuid }
      let(:update_action) { 'UPDATE' }
      let(:creation_audit) {
        audited_object.audits.first
      }
      let(:update_audit) { audited_object.audits.second }

      context 'with user not using software_agent' do
        let(:expected_audit_summary) {
        {
          created_on:  creation_audit.created_at,
          created_by:  creation_audit.user.audited_user_info,
          last_updated_on:  update_audit.created_at,
          last_updated_by:  update_audit.user.audited_user_info,
          deleted_on: nil,
          deleted_by: nil
        }}
        include_context 'current_user'
        include_context 'update event'

        it {
          is_expected.to eq expected_audit_summary
        }
      end

      context 'with user using a software_agent' do
        let(:expected_audit_summary) {
        {
          created_on:  creation_audit.created_at,
          created_by:  creation_audit.user.audited_user_info.merge!(
          {
            "agent": {
              "id": software_agent.id,
              "name": software_agent.name
            }
          }),
          last_updated_on:  update_audit.created_at,
          last_updated_by:  update_audit.user.audited_user_info.merge!(
          {
            "agent": {
              "id": software_agent.id,
              "name": software_agent.name
            }
          }),
          deleted_on: nil,
          deleted_by: nil
        }}
        include_context 'current_user.current_software_agent'
        include_context 'update event'

        it {
          is_expected.to eq expected_audit_summary
        }
      end
    end

    context 'deleted' do
      let(:creation_audit) {
        audited_object.audits.first
      }

      context 'without previous update' do
        let(:delete_audit) { audited_object.audits.second }

        context 'with user not using software_agent' do
          let(:expected_audit_summary) {
          {
            created_on:  creation_audit.created_at,
            created_by:  creation_audit.user.audited_user_info,
            last_updated_on:  nil,
            last_updated_by:  nil,
            deleted_on: delete_audit.created_at,
            deleted_by: delete_audit.user.audited_user_info
          }}
          include_context 'current_user'
          include_context 'deletion event'

          it {
            is_expected.to eq expected_audit_summary
          }
        end
        context 'with user using software_agent' do
          let(:expected_audit_summary) {
          {
            created_on:  creation_audit.created_at,
            created_by:  creation_audit.user.audited_user_info.merge!(
            {
              "agent": {
                "id": software_agent.id,
                "name": software_agent.name
              }
            }),
            last_updated_on:  nil,
            last_updated_by:  nil,
            deleted_on: delete_audit.created_at,
            deleted_by: delete_audit.user.audited_user_info.merge!(
            {
              "agent": {
                "id": software_agent.id,
                "name": software_agent.name
              }
            })
          }}
          include_context 'current_user.current_software_agent'
          include_context 'deletion event'

          it {
            is_expected.to eq expected_audit_summary
          }
        end
      end

      context 'with previous update' do
        let(:update_audit) { audited_object.audits.second }
        let(:delete_audit) { audited_object.audits.third }
        let(:update_attribute) { :project_role_id }
        let(:update_value) { SecureRandom.uuid }
        let(:update_action) { 'UPDATE' }

        context 'with user not using software_agent' do
          let(:expected_audit_summary) {
          {
            created_on:  creation_audit.created_at,
            created_by:  creation_audit.user.audited_user_info,
            last_updated_on:  update_audit.created_at,
            last_updated_by:  update_audit.user.audited_user_info,
            deleted_on:  delete_audit.created_at,
            deleted_by:  delete_audit.user.audited_user_info
          }}
          include_context 'current_user'
          include_context 'update event'
          include_context 'deletion event'

          it {
            is_expected.to eq expected_audit_summary
          }
        end
        context 'with user using software_agent' do
          let(:expected_audit_summary) {
          {
            created_on:  creation_audit.created_at,
            created_by:  creation_audit.user.audited_user_info.merge!(
            {
              "agent": {
                "id": software_agent.id,
                "name": software_agent.name
              }
            }),
            last_updated_on:  update_audit.created_at,
            last_updated_by:  update_audit.user.audited_user_info.merge!(
            {
              "agent": {
                "id": software_agent.id,
                "name": software_agent.name
              }
            }),
            deleted_on: delete_audit.created_at,
            deleted_by: delete_audit.user.audited_user_info.merge!(
            {
              "agent": {
                "id": software_agent.id,
                "name": software_agent.name
              }
            })
          }}
          include_context 'current_user.current_software_agent'
          include_context 'update event'
          include_context 'deletion event'

          it {
            is_expected.to eq expected_audit_summary
          }
        end
      end
    end
  end

  context 'logically deleted audited model' do
    let(:audited_object) { FactoryBot.create(:folder) }
    let(:creation_audit) {
      audited_object.audits.first
    }
    let(:delete_audit) { audited_object.audits.second }
    context 'deleted' do
      context 'with user not using software_agent' do
        let(:expected_audit_summary) {
        {
          created_on:  creation_audit.created_at,
          created_by:  creation_audit.user.audited_user_info,
          last_updated_on:  delete_audit.created_at,
          last_updated_by:  delete_audit.user.audited_user_info,
          deleted_on: delete_audit.created_at,
          deleted_by: delete_audit.user.audited_user_info
        }}
        include_context 'current_user'
        include_context 'logical deletion event'

        it {
          is_expected.to eq expected_audit_summary
        }
      end
      context 'with user using software_agent' do
        let(:expected_audit_summary) {
        {
          created_on:  creation_audit.created_at,
          created_by:  creation_audit.user.audited_user_info.merge!(
          {
            "agent": {
              "id": software_agent.id,
              "name": software_agent.name
            }
          }),
          last_updated_on:  delete_audit.created_at,
          last_updated_by:  delete_audit.user.audited_user_info.merge!(
          {
            "agent": {
              "id": software_agent.id,
              "name": software_agent.name
            }
          }),
          deleted_on: delete_audit.created_at,
          deleted_by: delete_audit.user.audited_user_info.merge!(
          {
            "agent": {
              "id": software_agent.id,
              "name": software_agent.name
            }
          })
        }}
        include_context 'current_user.current_software_agent'
        include_context 'logical deletion event'

        it {
          is_expected.to eq expected_audit_summary
        }
      end
    end

    context 'restorable and restored' do
      let(:restore_audit) { audited_object.audits.third }

      context 'with user not using software_agent' do
        let(:expected_audit_summary) {
        {
          created_on:  creation_audit.created_at,
          created_by:  creation_audit.user.audited_user_info,
          last_updated_on:  restore_audit.created_at,
          last_updated_by:  restore_audit.user.audited_user_info,
          restored_on:  restore_audit.created_at,
          restored_by:  restore_audit.user.audited_user_info,
          deleted_on: delete_audit.created_at,
          deleted_by: delete_audit.user.audited_user_info
        }}
        include_context 'current_user'
        include_context 'restoration event'

        it {
          is_expected.to eq expected_audit_summary
        }
      end
      context 'with user using software_agent' do
        let(:expected_audit_summary) {
        {
          created_on:  creation_audit.created_at,
          created_by:  creation_audit.user.audited_user_info.merge!(
          {
            "agent": {
              "id": software_agent.id,
              "name": software_agent.name
            }
          }),
          last_updated_on:  restore_audit.created_at,
          last_updated_by:  restore_audit.user.audited_user_info.merge!(
          {
            "agent": {
              "id": software_agent.id,
              "name": software_agent.name
            }
          }),
          restored_on:  restore_audit.created_at,
          restored_by:  restore_audit.user.audited_user_info.merge!(
          {
            "agent": {
              "id": software_agent.id,
              "name": software_agent.name
            }
          }),
          deleted_on: delete_audit.created_at,
          deleted_by: delete_audit.user.audited_user_info.merge!(
          {
            "agent": {
              "id": software_agent.id,
              "name": software_agent.name
            }
          })
        }}
        include_context 'current_user.current_software_agent'
        include_context 'restoration event'

        it {
          is_expected.to eq expected_audit_summary
        }
      end
    end

    context 'purged' do
      let(:purge_audit) { audited_object.audits.third }

      context 'with user not using software_agent' do
        let(:expected_audit_summary) {
        {
          created_on:  creation_audit.created_at,
          created_by:  creation_audit.user.audited_user_info,
          last_updated_on:  purge_audit.created_at,
          last_updated_by:  purge_audit.user.audited_user_info,
          purged_on:  purge_audit.created_at,
          purged_by:  purge_audit.user.audited_user_info,
          deleted_on: delete_audit.created_at,
          deleted_by: delete_audit.user.audited_user_info
        }}
        include_context 'current_user'
        include_context 'purge event'

        it {
          is_expected.to eq expected_audit_summary
        }
      end
      context 'with user using software_agent' do
        let(:expected_audit_summary) {
        {
          created_on:  creation_audit.created_at,
          created_by:  creation_audit.user.audited_user_info.merge!(
          {
            "agent": {
              "id": software_agent.id,
              "name": software_agent.name
            }
          }),
          last_updated_on:  purge_audit.created_at,
          last_updated_by:  purge_audit.user.audited_user_info.merge!(
          {
            "agent": {
              "id": software_agent.id,
              "name": software_agent.name
            }
          }),
          purged_on:  purge_audit.created_at,
          purged_by:  purge_audit.user.audited_user_info.merge!(
          {
            "agent": {
              "id": software_agent.id,
              "name": software_agent.name
            }
          }),
          deleted_on: delete_audit.created_at,
          deleted_by: delete_audit.user.audited_user_info.merge!(
          {
            "agent": {
              "id": software_agent.id,
              "name": software_agent.name
            }
          })
        }}
        include_context 'current_user.current_software_agent'
        include_context 'purge event'

        it {
          is_expected.to eq expected_audit_summary
        }
      end
    end
  end
end
