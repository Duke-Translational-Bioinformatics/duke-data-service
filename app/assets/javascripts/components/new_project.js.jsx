var NewProject = React.createClass({
  render: function() {
    return (
      <div className="modal fade"
           id="newProjectModal"
           tabindex="-1"
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
            <div className="modal-body">
              <p>this is the body</p>
            </div>
            <div className="modal-footer">
              <button type="button"
                      className="btn btn-default"
                      data-dismiss="modal">Close</button>
              <button type="button"
                      className="btn btn-primary">Save changes</button>
            </div>
          </div>
        </div>
      </div>
    )
  }
});
