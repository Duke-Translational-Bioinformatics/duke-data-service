var ProjectSummary = React.createClass({
  render: function() {
    return (
      <li className="list-group-item">
        <span className="fa-stack fa-2x pull-left">
          <i className="fa fa-square-o fa-stack-2x" />
          <i className="fa fa-folder fa-stack-1x" />
        </span>
        <p>Project {this.props.project.name}</p>
        <p>Description {this.props.project.description}</p>
      </li>
    )
  }
});
