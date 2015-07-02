var MainMenu = React.createClass({
  getInitialState: function() {
    return {active: false}
  },

  handleClick: function(event) {
    this.setState({active: !this.state.active});
  },

  render: function() {
    var iClassName = this.state.active ? "fa fa-times-circle fa-3x" : "fa fa-bars fa-3x"
    return (
      <li className="dropdown">
        <a className="dropdown-toggle" data-toggle="dropdown" onClick={this.handleClick}><i className={iClassName} /></a>
        {this.props.children}
      </li>
    )
  }
});
