var NewProjectMemberButton = React.createClass({
  handleClick: function() {
     React.render(
       <ProjectMemberForm {...this.props} />
      , document.getElementById('projectMemberFormTarget'));
      $("#ProjectMemberFormModal").modal('toggle');
  },

  render: function() {
    return (
      <a className="NewProjectMemberButton" onClick={this.handleClick}>
        <i className="fa fa-plus-circle fa-2x" />{this.props.label}
      </a>
    )
  }
});
