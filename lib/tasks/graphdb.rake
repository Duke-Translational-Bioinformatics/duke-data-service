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
