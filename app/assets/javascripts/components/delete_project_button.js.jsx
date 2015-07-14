var DeleteProjectButton = React.createClass({
  handleClick: function(e) {
    e.preventDefault();
    var jqReq = $.ajax({
      type: 'DELETE',
      url: '/api/v1/projects/'+this.props.project.id,
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
    this.props.deleteProject();
    var alert_suggestion = 'project deleted';
    this.props.alertUser({reason: '', suggestion: alert_suggestion}, 'success');
  },

  render: function() {
    return (
      <a className="DeleteProjectButton" onClick={this.handleClick} >
        <i className="fa fa-trash-o" />{this.props.label}
      </a>
    )
  }
});
