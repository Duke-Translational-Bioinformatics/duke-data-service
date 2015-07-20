var ProjectMemberSummary = React.createClass({

  handleSelectedRole: function(role, href, target) {
    payload = JSON.stringify({auth_role: role.id});
    var jqReq = $.ajax({
      type: 'PUT',
      url: '/api/v1/projects/'+this.props.project_member.project.id+'/permissions/'+this.props.project_member.user.id,
      beforeSend: function(xhr) {
        // set header
        xhr.setRequestHeader("Authorization", this.props.api_token);
      }.bind(this),
      data: payload,
      contentType: 'application/json',
      dataType: 'json'
    }).then(
      this.handleSuccess,
      this.props.handleAjaxError
    );
  },

  handleSuccess: function(data) {
    var alert_suggestion = '';
    if (this.props.project_member.auth_role) {
      this.props.project_member = data;
      alert_suggestion = 'project member role updated'
      this.forceUpdate();
    }
    else {
      this.props.addProjectMember(data);
      alert_suggestion = 'project member added';
    }
    this.props.alertUser({reason: '', suggestion: alert_suggestion}, 'success');
  },

  render: function() {
    return (
      <li className="list-group-item ProjectMemberSummary">
        <form className="form-inline">
          <label><DeleteProjectMemberButton {...this.props} />{this.props.project_member.user.full_name}</label>
          <ProjectMemberRoleChooser auth_role={this.props.project_member.auth_role} onSelect={this.handleSelectedRole} />
        </form>
      </li>
    )
  }
});
