var EditProjectButton = React.createClass({
  handleClick: function() {
     React.render(
       <ProjectForm {...this.props} />
      , document.getElementById('projectFormTarget'));
      $("#ProjectFormModal").modal('toggle');
  },

  render: function() {
    return (
      <a className="EditProjectButton" onClick={this.handleClick} >
        <i className="fa fa-pencil" />{this.props.label}
      </a>
    )
  }
});
