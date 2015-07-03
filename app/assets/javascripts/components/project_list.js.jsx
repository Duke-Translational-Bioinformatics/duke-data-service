var ProjectList = React.createClass({
  render: function() {
    var projectSummaries = this.props.projects.map(function(project) {
      return (
        <ProjectSummary key={project.id} project={project} />
      )
    });

    return (
      <ul className="list-group">
        {projectSummaries}
      </ul>
    )
  }
});
