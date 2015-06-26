var Navigation = ReactRouter.Navigation;

var SubMenu = React.createClass({
  mixins: [ Navigation ],

  render: function() {
    var displayStyle = this.props.isLoggedIn ? {display: 'block'} : {display: 'none'};
    return (
      <ul style={displayStyle} id="dashboard" className="nav navbar-nav">
        <li><a href=''>Link to Users</a></li>
      </ul>
    )
  }
});
