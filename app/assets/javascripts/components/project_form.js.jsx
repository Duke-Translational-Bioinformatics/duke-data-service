var ProjectForm = React.createClass({

  handleSubmit: function(e) {
    e.preventDefault();
    var resource_url = '/api/v1/projects';
    var request_type = 'POST';
    if (this.props.project && this.props.project.id) {
      resource_url = resource_url + '/' + this.props.project.id;
      request_type = 'PUT';
    }

    var jqReq = $.ajax({
      type: request_type,
      url: resource_url,
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
    $("#ProjectFormModal").modal('toggle');
  },

  handleSuccess: function(data) {
    if (this.props.project.id) {
      this.props.updateProject(data);
    }
    else {
      this.props.addToProjectList(data);
    }
    this.handleClose();
    var alert_suggestion = this.props.project ? 'project updated' : 'new project created';
    this.props.alertUser({reason: '', suggestion: alert_suggestion}, 'success');
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

  componentWillMount: function() {
    if (this.props.project) {
      this.setState({
        name: this.props.project.name,
        description: this.props.project.description
      });
    }
  },

  componentWillReceiveProps: function(nextProps) {
    this.setState({
      name: nextProps.project ? nextProps.project.name : "",
      description: nextProps.project ? nextProps.project.description : ""
    });
  },

  render: function() {
    var formAction = this.props.project ? "Edit Project " : "New Project";
    return (
      <div className="modal fade"
           id="ProjectFormModal"
           tabIndex="-1"
           role="dialog"
           aria-labelledby="ProjectFormModalLabel">
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
              <h4 className="modal-title" id="ProjectFormModalLabel">{formAction}</h4>
            </div>
            <form className="form-horizontal" onSubmit={this.handleSubmit}>
              <div className="modal-body">
                <div id="nameField" className="form-group">
                  <label id="nameStatus" className="col-sm-2 control-label" for="inputName">Name</label>
                  <div className="col-sm-10">
                    <input type="text" className="form-control" id="nameInput" placeholder="Project Name" value={this.state.name} onChange={this.handleNameChange} />
                  </div>
                  <div id="nameAlert"></div>
                </div>
                <div id="descriptionField" className="form-group">
                  <label id="descriptionStatus" className="col-sm-2 control-label" for="inputDescription">Description</label>
                  <div className="col-sm-10">
                    <textarea className="form-control" id="descriptionInput" placeholder="Project Description" value={this.state.description} onChange={this.handleDescriptionChange} />
                  </div>
                  <div id="descriptionAlert"></div>
                </div>
              </div>
              <div className="modal-footer">
                <button type="button"
                      className="btn btn-default"
                      onClick={this.handleClose}>Close</button>
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
