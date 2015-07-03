var AccountOverview = React.createClass({
  render: function() {
    return (
      <div className="row AccountOverview">
        <div className="col-md-3">
          <div className="panel panel-default">
            <p>{this.props.projects.length} Projects</p>
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
    )
  }
})
