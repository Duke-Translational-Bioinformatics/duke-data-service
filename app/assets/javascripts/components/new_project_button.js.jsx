var NewProjectButton = React.createClass({
  render: function() {
    return (
      <a className="NewProjectButton" data-toggle="modal" data-target="#newProjectModal">
        <i className="fa fa-plus-circle fa-2x" />{this.props.label}
      </a>
    )
  }
});
