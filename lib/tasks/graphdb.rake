def annotate_audit(parent_audit, audit)
  audit.update({
    request_uuid: parent_audit.request_uuid,
    remote_address: parent_audit.remote_address,
    comment: parent_audit.comment
  })
end

namespace :graphdb do
  desc "builds graph_nodes for all graphed models"
  task build: :environment do
    Rails.logger.level = 3
    artifacts = {}
    User.all.each do |user|
      unless user.graph_node
        user.create_graph_node
        if artifacts[:users]
          artifacts[:users] += 1
        else
          artifacts[:users] = 1
        end
        $stderr.print "+"
      end
    end

    SoftwareAgent.all.each do |sa|
      unless sa.graph_node
        sa.create_graph_node
        if artifacts[:software_agents]
          artifacts[:software_agents] += 1
        else
          artifacts[:software_agents] =  1
        end
        $stderr.print "+"
      end
    end

    FileVersion.all.each do |file_version|
      unless file_version.graph_node
        file_version.create_graph_node
        if artifacts[:file_versions]
          artifacts[:file_versions] += 1
        else
          artifacts[:file_versions] =  1
        end
        $stderr.print "+"
      end
      creation_audit = file_version.audits.where(action: 'create').take
      attributed_to_user = AttributedToUserProvRelation.where(
        relatable_to: creation_audit.user, relatable_from: file_version
      ).take
      unless attributed_to_user
        Audited.audit_class.as_user(creation_audit.user) do
          a2u = AttributedToUserProvRelation.create(
            creator: creation_audit.user, relatable_to: creation_audit.user, relatable_from: file_version
          )
          annotate_audit creation_audit, a2u.audits.last
          if artifacts[:attributed_to_user_prov_relations]
            artifacts[:attributed_to_user_prov_relations] += 1
          else
            artifacts[:attributed_to_user_prov_relations] =  1
          end
          $stderr.print "+"
        end
      end

      if creation_audit.comment && creation_audit.comment.has_key?("software_agent_id")
        sa = SoftwareAgent.find(creation_audit.comment["software_agent_id"])
        attributed_to_software_agent = AttributedToSoftwareAgentProvRelation.where(
          relatable_to: sa, relatable_from: file_version
        ).take
        unless attributed_to_software_agent
          Audited.audit_class.as_user(creation_audit.user) do
            a2sa = AttributedToSoftwareAgentProvRelation.create(
              creator: creation_audit.user, relatable_to: sa, relatable_from: file_version
            )
            annotate_audit creation_audit, a2sa.audits.last
            if artifacts[:attributed_to_software_agents_prov_relations]
              artifacts[:attributed_to_software_agents_prov_relations] += 1
            else
              artifacts[:attributed_to_software_agents_prov_relations] =  1
            end
            $stderr.print "+"
          end
        end
      end
    end

    Activity.all.each do |activity|
      unless activity.graph_node
        activity.create_graph_node
        if artifacts[:activities]
          artifacts[:activities] += 1
        else
          artifacts[:activities] =  1
        end
        $stderr.print "+"
      end
      creation_audit = activity.audits.where(action: 'create').take
      associated_with_user = AssociatedWithUserProvRelation.where(
        creator: creation_audit.user, relatable_from: creation_audit.user, relatable_to: activity
      ).take
      unless associated_with_user
        Audited.audit_class.as_user(creation_audit.user) do
          a2u = AssociatedWithUserProvRelation.create(
            creator: creation_audit.user, relatable_from: creation_audit.user, relatable_to: activity
          )
          annotate_audit creation_audit, a2u.audits.last
          if artifacts[:associated_with_user_prov_relations]
            artifacts[:associated_with_user_prov_relations] += 1
          else
            artifacts[:associated_with_user_prov_relations] =  1
          end
          $stderr.print "+"
        end
      end

      if creation_audit.comment && creation_audit.comment.has_key?("software_agent_id")
        sa = SoftwareAgent.find(creation_audit.comment["software_agent_id"])
        associated_with_software_agent = AssociatedWithSoftwareAgentProvRelation.where(
          creator: creation_audit.user, relatable_from: sa, relatable_to: activity
        ).take
        unless associated_with_software_agent
          Audited.audit_class.as_user(creation_audit.user) do
            a2sa = AssociatedWithSoftwareAgentProvRelation.create(
              creator: creation_audit.user, relatable_from: sa, relatable_to: activity
            )
            annotate_audit creation_audit, a2sa.audits.last
            if artifacts[:associated_with_user_prov_relations]
              artifacts[:associated_with_user_prov_relations] += 1
            else
              artifacts[:associated_with_user_prov_relations] =  1
            end
            $stderr.print "+"
          end
        end
      end
    end

    ProvRelation.all.each do |prov_relation|
      unless prov_relation.graph_relation
        prov_relation.create_graph_relation
        if artifacts[:prov_graph_relations]
          artifacts[:prov_graph_relations] += 1
        else
          artifacts[:prov_graph_relations] = 1
        end
        $stderr.print "+"
      end
    end

    $stderr.puts "\n\nArtifacts Created:"
    artifacts.keys.each do |artifact|
      $stderr.puts "#{artifact}: #{artifacts[artifact]}"
    end
  end

  desc "cleans everything in the graphdb (rebuild with rake graphdb:build)"
  task clean: :environment do
    Neo4j::Session.query('MATCH (n) OPTIONAL MATCH (n)-[r]-() DELETE n,r')
  end
end
