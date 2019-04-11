namespace :graphdb do
  desc "builds graph_nodes for all graphed models"
  task build: :environment do
    Rails.logger.level = 3
    artifacts = {}
    User.all.each do |user|
      begin
        user.graph_node
      rescue Neo4j::ActiveNode::Labels::RecordNotFound
        user.touch
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
      begin
        sa.touch
        sa.graph_node
      rescue Neo4j::ActiveNode::Labels::RecordNotFound
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
      begin
        file_version.touch
        file_version.graph_node
      rescue Neo4j::ActiveNode::Labels::RecordNotFound
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
      begin
        activity.touch
        activity.graph_node
      rescue Neo4j::ActiveNode::Labels::RecordNotFound
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
      begin
        prov_relation.touch
        prov_relation.graph_relation
      rescue Neo4j::ActiveNode::Labels::RecordNotFound
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
    Neo4j::ActiveBase.current_session.query('MATCH (n) OPTIONAL MATCH (n)-[r]-() DELETE n,r')
  end
end
