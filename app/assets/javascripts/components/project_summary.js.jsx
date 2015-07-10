var Link = ReactRouter.Link;

var ProjectSummary = React.createClass({

  render: function() {
    return (
      <li className="list-group-item ProjectSummary">
        <div className="row">
          <div className="col-md-1">
            <ul className="list-unstyled">
              <li><Link to="project_detail" params={this.props.project}><i className="fa fa-eye" /></Link></li>
              <li><EditProjectButton label='' {...this.props} /></li>
              <li><Link to="project_folders" params={this.props.project}><i className="fa fa-folder-o" /></Link></li>
              <li><Link to="project_members" params={this.props.project}><i className="fa fa-users" /></Link></li>
            </ul>
          </div>
          <div className="col-md-11">
            <p>Project {this.props.project.name}</p>
            <p>Description {this.props.project.description}</p>
          </div>
        </div>
      </li>
    )
  }
});
