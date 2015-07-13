var ProjectMembers = React.createClass({
  getInitialState: function() {
    return {
      project: '',
      project_members: []
    };
  },

  getProject: function(api_token, id) {
    var resourceUrl = '/api/v1/projects/'+id;
    return this.props.getResourceWithToken(api_token,'/api/v1/projects/'+id);
  },

  loadProject: function(data) {
    if (this.isMounted()) {
      this.setState({project: data});
      this.getProjectMembers(this.props.api_token, data.id).then(
        this.loadProjectMembers,
        this.props.handleAjaxError
      );
    }
  },

  getProjectMembers: function(api_token, project_id) {
    return this.props.getResourceWithToken(api_token,'/api/v1/projects');/* /'+project_id+'/permissions'); */
  },

  loadProjectMembers: function(data) {
    /*
    if (this.isMounted()) {
      this.setState({project_members: data});
    }
    */
  },

  addToProjectMemberList: function(project_member) {
    project_members = this.state.project_members
    project_members.push(project);
    this.setState({
      project_members: project_members
    });
  },

  componentDidMount: function() {
    this.props.setMainMenuItems([
      {
        link_to: "home",
        content: <i className="fa fa-dashboard" > Project Dashboard</i>
      },
      {
        link_to: "project_detail",
        link_params: {id: this.props.params.id},
        content: <i className="fa fa-eye"> Project Detail</i>
      },
      {
        link_to: "project_folders",
        link_params: {id: this.props.params.id},
        content: <i className="fa fa-folder-o"> Project Folders</i>
      }
    ]);
  },

  shouldComponentUpdate: function(nextProps, nextState) {
    if (this.props.api_token) {
      if (!this.state.project) {
        if (nextState.project.id){
          return true;
        }
        return true;
      }
      return false;
    }
    return false;
  },

  componentDidUpdate: function() {
    if (this.props.api_token && !this.state.project){
      this.getProject(this.props.api_token, this.props.params.id).then(
        this.loadProject,
        this.props.handleAjaxError
      );
    }
  },

  render: function() {
    return (
      <div>
        <div className="panel panel-default">
          <h3>Project {this.state.project.id} &gt; Members</h3>
          <NewProjectMemberButton
            {...this.props}
            addToProjectMemberList={this.addToProjectMemberList} />
        </div>
        <div id="projectMemberFormTarget" />
        <ProjectMemberList {...this.props} project={this.state.project} project_members={this.state.project_members} />
      </div>
    )
  }
});
