var MainMenu = React.createClass({
  render: function() {
    return (
      <li className="dropdown MainMenu">
        <a className="dropdown-toggle" data-toggle="dropdown"><i className="fa fa-bars fa-3x" /></a>
        <ul className="dropdown-menu MainMenu">
          {this.props.children}
        </ul>
      </li>
    )
  }
});
