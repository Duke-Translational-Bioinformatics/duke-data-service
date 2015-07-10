var ProjectDashboard = React.createClass({
  getProjects: function(api_token) {
    return this.props.getResourceWithToken(api_token,'/api/v1/projects');
  },

  loadProjects: function(data) {
    if (this.isMounted()) {
      this.setState({projects: data});
    }
  },

  addToProjectList: function(project) {
    projects = this.state.projects
    projects.push(project);
    this.setState({
      projects: projects
    });
  },

  getInitialState: function() {
    return {
      projects: []
    };
  },

  componentDidMount: function() {
    this.props.setMainMenuItems([{
      content: <NewProjectButton
                  {...this.props}
                  label="New Project"
                  addToProjectList={this.addToProjectList} />
    }]);
    this.getProjects(this.props.api_token).then(
      this.loadProjects,
      this.props.handleAjaxError
    );
  },

  render: function() {
    var projects = this.state.projects;
    return (
      <div className="ProjectDashboard">
        <div id="projectFormTarget"></div>
        <AccountOverview projects={projects} />
        <ProjectList {...this.props} addToProjectList={this.addToProjectList} projects={projects} />
      </div>
    )
  }
});
