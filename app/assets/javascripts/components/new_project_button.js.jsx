var NewProjectButton = React.createClass({
  render: function() {
    return (
      <a><i className="fa fa-plus-circle fa-3x" />{this.props.label}</a>
    )
  }
});
