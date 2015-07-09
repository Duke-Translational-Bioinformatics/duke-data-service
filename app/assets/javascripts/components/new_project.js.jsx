var NewProject = React.createClass({

  handleSubmit: function(e) {
    e.preventDefault();
    var jqReq = $.ajax({
      type: 'POST',
      url: '/api/v1/projects',
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

  handleSuccess: function(data) {
    this.props.addToProjectList(data);
    ['name','description'].map(function(field) {
      $("#"+field+"Field").addClass('has-success');
      $("#"+field+"Field").removeClass('has-error');
      $("#"+field+"Alert").html("");
      $("#"+field+"Input").val("");
    });
    $("#newProjectModal").modal('toggle');
    this.props.alertUser({reason: '', suggestion: 'new project created'}, 'success');
  },

  handleNameChange: function(e) {
    this.setState({name: event.target.value});
  },

  handleDescriptionChange: function(e) {
    this.setState({description: event.target.value});
  },

  getInitialState: function() {
     return {
      name: '',
      description: ''
    }
  },

  render: function() {
    return (
      <div className="modal fade"
           id="newProjectModal"
           tabIndex="-1"
           role="dialog"
           aria-labelledby="newProjectModalLabel">
        <div className="modal-dialog"
             role="document">
          <div className="modal-content">
            <div className="modal-header">
              <button type="button"
                      className="close"
                      data-dismiss="modal"
                      aria-label="Close">
                <span aria-hidden="true">&times;</span>
              </button>
              <h4 className="modal-title" id="newProjectModalLabel">New Project</h4>
            </div>
            <form className="form-horizontal" onSubmit={this.handleSubmit}>
              <div className="modal-body">
                <div id="nameField" className="form-group">
                  <label id="nameStatus" className="col-sm-2 control-label" for="inputName">Name</label>
                  <div className="col-sm-10">
                    <input type="text" className="form-control" id="nameInput" placeholder="Project Name" onChange={this.handleNameChange} />
                  </div>
                  <div id="nameAlert"></div>
                </div>
                <div id="descriptionField" className="form-group">
                  <label id="descriptionStatus" className="col-sm-2 control-label" for="inputDescription">Description</label>
                  <div className="col-sm-10">
                    <textarea className="form-control" id="descriptionInput" placeholder="Project Description" onChange={this.handleDescriptionChange} />
                  </div>
                  <div id="descriptionAlert"></div>
                </div>
              </div>
              <div className="modal-footer">
                <button type="button"
                      className="btn btn-default"
                      data-dismiss="modal">Close</button>
                <input className="btn btn-primary"
                     type="submit" value="Submit" />
              </div>
            </form>
          </div>
        </div>
      </div>
    )
  }
});
