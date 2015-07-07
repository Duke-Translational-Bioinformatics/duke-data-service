var ProjectDashboard = React.createClass({
  getProjects: function(api_token) {
    return this.props.getResourceWithToken(api_token,'/api/v1/projects');
  },

  loadProjects: function(data) {
    if (this.isMounted()) {
      this.setState({projects: data});
    }
  },

  getInitialState: function() {
    return {
      projects: []
    };
  },

  componentDidMount: function() {
    this.props.setMainMenuItems([{content: <NewProjectButton label="New Project" />}]);
    this.getProjects(this.props.api_token).then(
      this.loadProjects,
      this.props.handleAjaxError
    );
  },

  render: function() {
    var projects = this.state.projects;
    return (
      <div className="ProjectDashboard">
        <NewProject handleCreateProject={this.handleCreateProject}/>
        <AccountOverview projects={projects} />
        <ProjectList projects={projects} />
      </div>
    )
  }
});
