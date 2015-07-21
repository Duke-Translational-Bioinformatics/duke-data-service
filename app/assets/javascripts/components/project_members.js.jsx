var ProjectMembers = React.createClass({
  getInitialState: function() {
    return {
      project: '',
      project_members: []
    };
  },

  getProject: function(id) {
    var resourceUrl = '/api/v1/projects/'+id;
    return this.props.getResourceWithToken(this.props.api_token,'/api/v1/projects/'+id);
  },

  loadProject: function(data) {
    if (this.isMounted()) {
      this.setState({project: data});
      this.getProjectMembers(data.id).then(
        this.loadProjectMembers,
        this.props.handleAjaxError
      );
    }
  },

  getProjectMembers: function(project_id) {
    var pmUrl = '/api/v1/projects/'+project_id+'/permissions';
    return this.props.getResourceWithToken(this.props.api_token,pmUrl);
  },

  loadProjectMembers: function(data) {
    if (this.isMounted()) {
      this.setState({project_members: data});
    }
  },

  addToProjectMemberList: function(project_member) {
    project_members = this.state.project_members
    project_members.push(project_member);
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
    React.render(<SearchMenu handleSearchChange={this.handleSearchChange} />, document.getElementById('search_menu'));
  },

  shouldComponentUpdate: function(nextProps, nextState) {
    if (this.props.api_token) {
      return true;
    }
    return false;
  },

  componentDidUpdate: function() {
    if (this.props.api_token && !this.state.project){
      this.getProject(this.props.params.id).then(
        this.loadProject,
        this.props.handleAjaxError
      );
    }
  },

/* Search Menu Functions */
  handleAjaxError: function(jqXHR, status, err) {
    switch(jqXHR.status) {
    case 404:
      break;
    default:
      this.props.handleAjaxError(jqXHR, status, err);
      break;
    }
  },

  getUserSuggestions: function(display_name_contains) {
    var usersUrl = '/api/v1/users?display_name_contains='+display_name_contains;
    return this.props.getResourceWithToken(this.props.api_token, usersUrl);
  },

  getProjectMember: function(user_id) {
    var resourceUrl = '/api/v1/projects/'+this.props.params.id+'/permissions/'+user_id;
    return this.props.getResourceWithToken(this.props.api_token, resourceUrl);
  },

  loadUserSuggestions: function(data) {
    projectMembers = [];
    data['results'].map(function(user, index) {
      /* default is to push the user without auth_roles */
      projectMembers[index] = {
        project: this.state.project,
        user: user,
        auth_role: null
      };

      this.getProjectMember(user.id).then(
         function(data){
           if (data){
             projectMembers[index].auth_role = data.auth_role
           }
         },
         this.handleAjaxError
      );
    }.bind(this));
    this.setState({project_members: projectMembers});
  },

  handleSearchChange: function(event) {
    if (event.target.value){
      this.getUserSuggestions(event.target.value).then(
        this.loadUserSuggestions,
        this.handleAjaxError
      );
    }
    else {
      this.getProjectMembers(this.props.params.id).then(
        this.loadProjectMembers,
        this.props.handleAjaxError
      );
    }
  },

  render: function() {
    return (
      <div>
        <div className="panel panel-default">
          <h3>Project {this.state.project.id} &gt; Members</h3>
        </div>
        <ProjectMemberList {...this.props}
           addProjectMember={this.addToProjectMemberList}
           project={this.state.project}
           project_members={this.state.project_members} />
      </div>
    )
  }
});
