var ProjectList = React.createClass({
  render: function() {
    var projectSummaries = this.props.projects.map(function(project) {
      return (
        <ProjectSummary key={project.uid} project={project} />
      )
    });

    return (
      <div className="projectList">
        {projectSummaries}
      </div>
    )
  }
});

var ProjectSummary = React.createClass({
  render: function() {
    return (
      <div className="projectSummary">
        <p>Project {this.props.project.name}</p>
        <p>Description {this.props.project.description}</p>
      </div>
    )
  }
});
