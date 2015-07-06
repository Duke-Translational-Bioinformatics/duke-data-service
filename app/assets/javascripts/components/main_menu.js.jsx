var MainMenu = React.createClass({
  getInitialState: function() {
    return {
      active: false
    }
  },

  handleClick: function(event) {
    this.setState({active: !this.state.active});
  },

  render: function() {
    var iClassName = this.state.active ? "fa fa-times-circle fa-3x" : "fa fa-bars fa-3x"
    var itemKey = 0;
    var menuItems = this.props.menuItems.concat([
      <a><i className="fa fa-info-circle fa-2x" />About</a>,
      <a>Terms & Conditions</a>
    ]).map(function(menuItem) {
      itemKey = itemKey + 1;
      return (
        <li key={itemKey}>{menuItem}</li>
      )
    });
    return (
      <li className="dropdown MainMenu">
        <a className="dropdown-toggle" data-toggle="dropdown" onClick={this.handleClick}><i className={iClassName} /></a>
        <ul className="dropdown-menu MainMenu">
          {menuItems}
        </ul>
      </li>
    )
  }
});
