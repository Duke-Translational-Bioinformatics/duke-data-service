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
    this.loadProjects();
    this.props.setMainMenuItems([<NewProjectButton label="New Project" />]);
    this.getProjects(this.props.api_token).then(
      this.loadProjects,
      this.props.handleAjaxError
    );
  },

  render: function() {
    return (
      <div className="ProjectDashboard">
        <NewProject />
        <AccountOverview projects={this.state.projects} />
        <ProjectList projects={this.state.projects} />
      </div>
    )
  }
});
