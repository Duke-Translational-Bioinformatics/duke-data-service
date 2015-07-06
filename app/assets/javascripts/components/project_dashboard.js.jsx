var ProjectDashboard = React.createClass({
  loadProjects: function() {
    this.setState({projects: [
      {
        "id": "ca29f7df-33ca-46dd-a015-92c46fdb6fd1",
        "name": "Knockout Mouse Project (KOMP)",
        "description": "Goal of generating a targeted knockout mutation...",
        "is_deleted": false
      },
      {
        "id": "ac927ffd-ca33-dd46-0a51-c492db6fd16f",
        "name": "Mouse RNASeq",
        "description": "RNASeq of reverse transcriptase",
        "is_deleted": false
      },
      {
        "id": "92c46fdb6fd1-a015-46dd-33ca-ca29f7df",
        "name": "Mouse Behavior",
        "description": "Observations of Mouse behaviors",
        "is_deleted": false
      },
    ]});
  },

  getInitialState: function() {
    return {
      projects: []
    };
  },

  componentDidMount: function() {
    this.loadProjects();
    this.props.setMainMenuItems([<NewProjectButton label="New Project" />]);
  },

  render: function() {
    return (
      <div className="ProjectDashboard">
        <AccountOverview projects={this.state.projects} />
        <ProjectList projects={this.state.projects} />
      </div>
    )
  }
});
