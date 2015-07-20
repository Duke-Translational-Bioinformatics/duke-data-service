var ProjectMemberRoleChooser = React.createClass({

  getRoleOptions: function() {
    var promise = new Promise(function(resolve, reject) {
      resolve({
        results: [
          {id: "project_admin",	name: "Project Admin", description: "Can update project details, delete project, manage project level permissions and perform all file operations", permissions: "view_project, update_project, delete_project, manage_project_permissions, download_file, create_file, update_file, delete_file"},
          {id: "project_viewer", name: "Project Viewer", description: "Can only view project and file meta-data", permissions: "view_project"},
          {id: "file_downloader", name:	"File Downloader", description:	"Can download files",	permissions: "view_project, download_file"},
          {id: "file_editor", name: "File Editor", description: "Can view, download, create, update and delete files", permissions: "view_project, download_file, create_file, update_file, delete_file"}
        ]
      });
    });
    return promise;
  },

  getInitialState: function() {
    return {role_options: []}
  },

  componentDidMount: function() {
    this.getRoleOptions().then(
      function(data) {
        this.setState({role_options: data['results']});
      }.bind(this)
    );
  },

  render: function() {
    var default_title = 'Role';
    var roleOptions = this.state.role_options.map(
      function(result, i) {
       console.log("Checking "+this.props.auth_role.id+" vs "+result.id);
       if (this.props.auth_role && this.props.auth_role.id == result.id) {
         default_title = result.id;
         return (
           <ReactBootstrap.MenuItem key={i} active={true} eventKey={result}>{result['name']}</ReactBootstrap.MenuItem>
         )
       }
       else {
         return (
           <ReactBootstrap.MenuItem key={i} active={false} eventKey={result}>{result['name']}</ReactBootstrap.MenuItem>
         )
       }
    }.bind(this));

    return (
      <ReactBootstrap.DropdownButton title={default_title} onSelect={this.props.onSelect}>
       {roleOptions}
      </ReactBootstrap.DropdownButton>
    )
  }
});
