var ProjectMemberForm = React.createClass({

  handleSubmit: function(e) {
    e.preventDefault();
    var request_type = 'POST';
    var jqReq = $.ajax({
      type: 'POST',
      url: '/api/v1/project/'+this.props.project.id+'/permissions',
      beforeSend: function(xhr) {
        // set header
        xhr.setRequestHeader("Authorization", this.props.api_token);
      }.bind(this),
      data: JSON.stringify(this.state),
      contentType: 'application/json',
      dataType: 'json'
    }).then(
      this.handleSuccess,
      this.props.handleAjaxError
    );
  },

  handleClose: function(e) {
    if (e) {
      e.preventDefault();
    }
    ['name','description'].map(function(field) {
      $("#"+field+"Field").removeClass('has-error');
      $("#"+field+"Alert").html("");
      $("#"+field+"Input").val("");
    });
    $("#ProjectMemberFormModal").modal('toggle');
  },

  handleSuccess: function(data) {
    this.props.addToProjectMemberList(data);
    this.handleClose();
    var alert_suggestion = 'new project member added';
    this.props.alertUser({reason: '', suggestion: alert_suggestion}, 'success');
  },

  handleMemberIdChange: function(e) {
    this.setState({member_id: event.target.value});
  },

  handleRoleChange: function(e) {
    this.setState({description: event.target.value});
  },

  getInitialState: function() {
     return {
      member_id: '',
      role: ''
    }
  },

  render: function() {
    return (
      <div className="modal fade"
           id="ProjectMemberFormModal"
           tabIndex="-1"
           role="dialog"
           aria-labelledby="ProjectMemberFormModalLabel">
        <div className="modal-dialog"
             role="document">
          <div className="modal-content">
            <div className="modal-header">
              <button type="button"
                      className="close"
                      onClick={this.handleClose}
                      aria-label="Close">
                <span aria-hidden="true">&times;</span>
              </button>
              <h4 className="modal-title" id="ProjectMemberFormModalLabel">Add Project Member</h4>
            </div>
            <form className="form-horizontal" onSubmit={this.handleSubmit}>
              <div className="modal-body">
                <div id="nameField" className="form-group">
                  <label id="memberIdStatus" className="col-sm-2 control-label" for="inputMemberId">Member</label>
                  <div className="col-sm-10">
                    <input type="text" className="form-control" id="memberIdInput" placeholder="Member" value={this.state.member_id} onChange={this.handleMemberIdChange} />
                  </div>
                  <div id="memberIdAlert"></div>
                </div>
                <div id="roleField" className="form-group">
                  <label id="roleStatus" className="col-sm-2 control-label" for="inputDescription">Role</label>
                  <div className="col-sm-10">
                    <input type='text' className="form-control" id="roleInput" placeholder="Role" value={this.state.role} onChange={this.handleRoleChange} />
                  </div>
                  <div id="roleAlert"></div>
                </div>
              </div>
              <div className="modal-footer">
                <button type="button"
                      className="btn btn-default"
                      onClick={this.handleClose}>Close</button>
                <input className="btn btn-primary"
                     type="submit" value="Add" />
              </div>
            </form>
          </div>
        </div>
      </div>
    )
  }
});
