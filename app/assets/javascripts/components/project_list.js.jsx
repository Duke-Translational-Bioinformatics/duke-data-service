var ProjectList = React.createClass({

  updateProject: function(project_index, data) {
   this.props.projects[project_index] = data;
   this.forceUpdate();
  },

  deleteProject: function(project_index) {
   delete this.props.projects[project_index];
   this.forceUpdate();
  },

  render: function() {
    var projectSummaries = this.props.projects.map(function(project, i) {
      return (
        <ProjectSummary
          key={i}
          project_index={i}
          updateProject={this.updateProject.bind(this, i)}
          deleteProject={this.deleteProject.bind(this, i)}
          project={project} {...this.props} />
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
