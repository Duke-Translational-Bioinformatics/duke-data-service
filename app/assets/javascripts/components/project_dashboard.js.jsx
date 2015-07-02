var ProjectDashboard = React.createClass({
  loadProjects: function() {
    this.setState({projects: [
      {
        "uid": "ca29f7df-33ca-46dd-a015-92c46fdb6fd1",
        "name": "Knockout Mouse Project (KOMP)",
        "description": "Goal of generating a targeted knockout mutation...",
        "is_deleted": false
      },
      {
        "uid": "ac927ffd-ca33-dd46-0a51-c492db6fd16f",
        "name": "Mouse RNASeq",
        "description": "RNASeq of reverse transcriptase",
        "is_deleted": false
      },
      {
        "uid": "92c46fdb6fd1-a015-46dd-33ca-ca29f7df",
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
        <div className="navbar navbar-default" role="navigation">
          <ul className="nav navbar-nav">
            <li>
              <a><i className="fa fa-bars fa-3x" /></a>
            </li>
            <li className="dropdown">
              <a className="navbar-brand">Projects</a>
            </li>
            <ul className="nav navbar-nav navbar-right">
              <li className="dropdown">
                <a><i className="fa fa-plus-circle fa-3x" /></a>
              </li>
            </ul>
          </ul>
        </div>
        <ProjectList projects={this.state.projects} />
      </div>
    )
  }
});
