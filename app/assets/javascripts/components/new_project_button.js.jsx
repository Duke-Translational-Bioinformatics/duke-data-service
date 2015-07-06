var NewProjectButton = React.createClass({
  render: function() {
    return (
      <a className="NewProjectButton"><i className="fa fa-plus-circle fa-2x" />{this.props.label}</a>
    )
  }
});
