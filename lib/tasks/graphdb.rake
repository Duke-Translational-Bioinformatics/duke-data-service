namespace :graphdb do
  desc "builds graph_nodes for all graphed models"
  task build: :environment do
    User.all.each do |user|
      user.graph_node
    end

    SoftwareAgent.all.each do |sa|
      sa.graph_node
    end

    FileVersion.all.each do |fv|
      fv.graph_node
    end
  end

  desc "cleans everything in the graphdb (rebuild with rake graphdb:build)"
  task clean: :environment do
    Neo4j::Session.query('MATCH (n) OPTIONAL MATCH (n)-[r]-() DELETE n,r')
  end
end
