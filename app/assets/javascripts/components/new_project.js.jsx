var NewProject = React.createClass({

  handleSubmit: function(e) {
    e.preventDefault();
    var name = React.findDOMNode(this.refs.project_name).value.trim();
    var description = React.findDOMNode(this.refs.project_description).value.trim();

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
                    <input type="text" className="form-control" id="inputName" placeholder="Project Name" ref="project_name" />
                  </div>
                </div>
                <div id="descriptionField" className="form-group">
                  <label id="descriptionStatus" className="col-sm-2 control-label" for="inputDescription">Description</label>
                  <div className="col-sm-10">
                    <input type="text" className="form-control" id="inputDescription" placeholder="Project Description" ref="project_description" />
                  </div>
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
