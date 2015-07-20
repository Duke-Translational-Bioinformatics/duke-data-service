var ProjectMemberForm = React.createClass({

  handleAjaxError: function(jqXHR, status, err) {
    this.handleClose();
    this.props.handleAjaxError(jqXHR, status, err);
  },

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
    this.setState({member_id: selectedOption.id});
  },

  getUserSuggestions: function(display_name_contains) {
    var usersUrl = '/api/v1/users?display_name_contains='+display_name_contains;
    return this.props.getResourceWithToken(this.props.api_token, usersUrl);
  },

  loadUserSuggestions: function(data) {
    this.setState({
      typeaheadOptions: data['results']
    });
  },

  handleMemberIdChange: function(e) {
    if ( event.target.value.length > 2 ) {
      this.getUserSuggestions(event.target.value).then(
        this.loadUserSuggestions,
        this.handleAjaxError
      )
    }
    else {
      this.setState({
        member_id: '',
        typeaheadOptions: [],
        roleOptions: []
      })
    }
  },

  handleSelectedRole: function(eventKey, href, target) {
    console.log("GOT eventKey "+JSON.stringify(eventKey)+" href "+href+" target "+target);
  },

  getInitialState: function() {
     return {
      member_id: '',
      role: '',
      typeaheadOptions: [],
      roleOptions: []
    }
  },

  last_first_name: function(option) {
    return option.last_name+', '+option.first_name
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
                <div id="memberField" className="form-group">
                  <label id="memberIdStatus" className="col-sm-2 control-label">Member</label>
                  <div className="col-sm-10">
                    <ReactTypeahead.Typeahead
                      options={this.state.typeaheadOptions}
                      maxVisible={5}
                      displayOption={this.last_first_name}
                      filterOption='display_name'
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
                    <ProjectMemberRoleChooser onSelect={this.handleSelectedRole} />
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
