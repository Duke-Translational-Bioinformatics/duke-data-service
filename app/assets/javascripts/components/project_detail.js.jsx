var ProjectDetail = React.createClass({

  getInitialState: function() {
    return {
      project: ''
    };
  },

  getProject: function(api_token, id) {
    var resourceUrl = '/api/v1/projects/'+id;
    return this.props.getResourceWithToken(api_token,'/api/v1/projects/'+id);
  },

  loadProject: function(data) {
    if (this.isMounted()) {
      this.setState({project: data});
    }
  },

  componentDidMount: function() {
    this.props.setMainMenuItems([
      {
        link_to: "projects",
        content: <i className="fa fa-dashboard" > Project Dashboard</i>
      },
      {
        link_to: "project_folders",
        link_params: {id: this.props.params.id},
        content: <i className="fa fa-folder-o"> Project Folders</i>
      },
      {
        link_to: "project_folders",
        link_params: {id: this.props.params.id},
        content: <i className="fa fa-users"> Project Members</i>
      }
    ]);
    this.getProject(this.props.api_token, this.props.params.id).then(
      this.loadProject,
      this.props.handleAjaxError
    );
  },

  render: function() {
    return (
      <div>
        <p>Project {this.state.project.id} Details</p>
      </div>
    )
  }
});
