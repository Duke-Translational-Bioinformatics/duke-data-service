var ProjectList = React.createClass({
  render: function() {
    var projectSummaries = this.props.projects.map(function(project) {
      return (
        <ProjectSummary key={project.id} project={project} {...this.props} />
      )
    }.bind(this));

    return (
      <div>
        <div className="row panel panel-default">
          <div className="col-md-6">
            <p>Projects</p>
          </div>
          <div className="col-md-6">
            <div className="push-right">
              <NewProjectButton
                {...this.props}
                addToProjectList={this.props.addToProjectList}
                label={''} />
            </div>
          </div>
        </div>
        <div cassName="row">
          <ul className="list-group ProjectList">
            {projectSummaries}
          </ul>
        </div>
      </div>
    )
  }
});
