var ProjectSummary = React.createClass({
  render: function() {
    return (
      <li className="list-group-item">
        <i className="fa fa-folder fa-border fa-3x pull-left" />
        <p>Project {this.props.project.name}</p>
        <p>Description {this.props.project.description}</p>
      </li>
    )
  }
});
