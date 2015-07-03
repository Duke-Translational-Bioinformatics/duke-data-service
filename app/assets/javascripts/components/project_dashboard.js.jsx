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
  },

  render: function() {
    return (
      <div>
        <div className="navbar navbar-default">
          <ul className="nav navbar-nav navbar-left">
            <MainMenu>
              <ProjectMenu />
            </MainMenu>
            <form className="navbar-form navbar-left">
              <div className="form-group">
                <input type="text" className="form-control" placeholder="Search" />
              </div>
            </form>
          </ul>
          <ul className="nav navbar-nav navbar-right">
            <li>
               <NewProjectButton label={''}/>
            </li>
          </ul>
        </div>
        <AccountOverview projects={this.state.projects} />
        <ProjectList projects={this.state.projects} />
      </div>
    )
  }
});

var ProjectMenu = React.createClass({
  render: function() {
    return (
      <ul className="dropdown-menu">
        <li>
          <NewProjectButton label="New Project" />
        </li>
      </ul>
    )
  }
})
