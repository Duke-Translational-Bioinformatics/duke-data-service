var ProjectMemberList = React.createClass({

  deleteProjectMember: function(index) {
    delete this.props.project_members[index];
    this.forceUpdate();
  },

  render: function() {
    var projectMemberSummaries = this.props.project_members.map(function(project_member, i) {
      return (
        <ProjectMemberSummary
          key={i}
          project_member_index={i}
          deleteProjectMember={this.deleteProjectMember.bind(this, i)}
          project_member={project_member} {...this.props} />
      )
    }.bind(this));
    return (
      <div className="panel panel-default">
        <ul className="list-group ProjectMemberList">
          {projectMemberSummaries}
        </ul>
      </div>
    )
  }
});
