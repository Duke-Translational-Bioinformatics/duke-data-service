var ProjectDetail = React.createClass({
  componentDidMount: function() {
    this.props.setMainMenuItems([
      {
        link_to: "projects",
        content: <i className="fa fa-dashboard" > Project Dashboard</i>
      },
      {
        link_to: "project_folders",
        link_params: {id: this.props.params.id},
        content: <i className="fa fa-folder-o"> Project Folders</i>
      },
      {
        link_to: "project_folders",
        link_params: {id: this.props.params.id},
        content: <i className="fa fa-users"> Project Members</i>
      }
    ]);
  },

  render: function() {
    return (
      <div>
        <p>Project {this.props.params.id} Details</p>
      </div>
    )
  }
});
