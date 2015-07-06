var AccountOverview = React.createClass({
  render: function() {
    var numProjects = this.props.projects.length;
    return (
      <div className="panel panel-default AccountOverview">
        <p className="panel">Account Overview</p>
        <div className="row">
          <div className="col-md-3">
            <div className="panel panel-default">
              <p>{numProjects} Projects</p>
            </div>
          </div>
          <div className="col-md-3">
            <div className="panel panel-default">
              <p>37 Files</p>
            </div>
          </div>
          <div className="col-md-3">
            <div className="panel panel-default">
              <p>99.9 GB Data</p>
            </div>
          </div>
        </div>
      </div>
    )
  }
})
