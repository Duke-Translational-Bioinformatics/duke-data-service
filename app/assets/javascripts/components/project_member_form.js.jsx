var ProjectMemberForm = React.createClass({

  handleSubmit: function(e) {
    e.preventDefault();
    var submitOptions = {
      member_id: this.state.member_id,
      role: this.state.role
    }
    console.log("WOULD SUBMIT "+JSON.stringify(submitOptions));
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

  handleMemberIdSelected: function(selectedOption) {
    console.log("Selected "+JSON.stringify(selectedOption))
    this.setState({member_id: selectedOption.id});
  },

  getUserSuggestions: function(last_name_begins_with) {
    var usersUrl = '/api/v1/users?last_name_begins_with='+last_name_begins_with;
    console.log("getting "+usersUrl+" with "+this.props.api_token);
    return this.props.getResourceWithToken(this.props.api_token, usersUrl);
  },

  handleAjaxError: function(jqXHR, status, err) {
    this.handleClose();
    this.props.handleAjaxError(jqXHR, status, err);
  },

  loadUserSuggestions: function(data) {
    console.log("Got UserSuggestions "+JSON.stringify(data));
    this.setState({
      typeaheadOptions: data['results']
    });
  },

  handleMemberIdChange: function(e) {
    console.log("MemberID changed to "+event.target.value);
    if ( event.target.value.length > 2 ) {
      console.log("Setting options");
      this.getUserSuggestions(event.target.value).then(
        this.loadUserSuggestions,
        this.handleAjaxError
      )
    }
    else {
      console.log("resetting");
      this.setState({
        member_id: '',
        typeaheadOptions: []
      })
    }
  },

  handleRoleChange: function(e) {
    this.setState({description: event.target.value});
  },

  getInitialState: function() {
     return {
      member_id: '',
      role: '',
      typeaheadOptions: []
    }
  },

  last_first_name: function(option) {
    return option.last_name+', '+option.first_name
  },

  render: function() {
    console.log("rendering");
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
                <div id="memberField" className="form-group">
                  <label id="memberIdStatus" className="col-sm-2 control-label">Member</label>
                  <div className="col-sm-10">
                    <ReactTypeahead.Typeahead
                      options={this.state.typeaheadOptions}
                      maxVisible={5}
                      displayOption={this.last_first_name}
                      filterOption='last_name'
                      customClasses={{
                        input: "form-control"
                      }}
                      id="memberIdInput"
                      placeholder="Member"
                      onKeyUp={this.handleMemberIdChange}
                      onOptionSelected={this.handleMemberIdSelected}
                      inputProps={{
                        value: this.state.member_id
                      }} />
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
