var DeleteProjectMemberButton = React.createClass({
  handleClick: function(e) {
    e.preventDefault();
    var jqReq = $.ajax({
      type: 'DELETE',
      url: '/api/v1/projects/'+this.props.project_member.project.id+'/permissions/'+this.props.project_member.user.id,
      beforeSend: function(xhr) {
        // set header
        xhr.setRequestHeader("Authorization", this.props.api_token);
      }.bind(this),
      contentType: 'application/json',
      dataType: 'json'
    }).then(
      this.handleSuccess,
      this.props.handleAjaxError
    );
  },

  handleSuccess: function(data) {
    this.props.deleteProjectMember();
    var alert_suggestion = 'project membership removed';
    this.props.alertUser({reason: '', suggestion: alert_suggestion}, 'success');
  },

  render: function() {
    if (this.props.project_member.auth_role) {
      return (
        <a className="DeleteProjectMemberButton" onClick={this.handleClick} >
          <i className="fa fa-trash-o" />
        </a>
      )
    }
    else {
      return (<div id="deleteProjectButtonTarget" />)
    }
  }
});
